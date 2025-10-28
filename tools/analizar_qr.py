from PIL import Image, ImageEnhance, ImageFilter
from pyzbar.pyzbar import decode
import cv2
import numpy as np
import os
import sys


# === CONFIGURACIÓN ===
DEFAULT_IMG_PATH = r"c:\rindegasto\img\image.png"


def mejorar_imagen_pil(img_pil: Image.Image) -> Image.Image:
    """Mejora contraste y nitidez de una imagen PIL"""
    img = img_pil.convert("L")  # Escala de grises
    img = img.filter(ImageFilter.SHARPEN)
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(3.0)
    img = img.filter(ImageFilter.EDGE_ENHANCE_MORE)
    return img


def leer_con_pyzbar(img_pil: Image.Image):
    """Intenta leer QR con pyzbar en una imagen PIL"""
    decoded_objects = decode(img_pil)
    return [obj.data.decode("utf-8") for obj in decoded_objects]


def leer_con_opencv(path_or_array):
    """Plan B: usa OpenCV QRCodeDetector sobre la imagen en path o array"""
    try:
        if isinstance(path_or_array, str):
            img = cv2.imread(path_or_array)
        else:
            img = path_or_array
        if img is None:
            return []
        detector = cv2.QRCodeDetector()
        data, points, _ = detector.detectAndDecode(img)
        if data:
            return [data]
    except Exception:
        pass
    return []


def pil_to_cv_gray(img_pil: Image.Image):
    arr = np.array(img_pil.convert('L'))
    return arr


def intentar_varias_estrategias(path):
    """Genera varias versiones de la imagen y las prueba con pyzbar y OpenCV."""
    attempts = []
    try:
        orig = Image.open(path)
    except Exception as e:
        print(f"ERROR_OPEN:{e}", file=sys.stderr)
        return []

    # estrategia 1: original -> pyzbar
    attempts.append(("original", orig))

    # estrategia 2: mejorada (contraste/nitidez)
    attempts.append(("mejorada", mejorar_imagen_pil(orig)))

    # estrategia 3: escalada 2x (mejora capacidad de detectar QR pequeños)
    w, h = orig.size
    attempts.append(("escalada_x2", orig.resize((w * 2, h * 2), Image.LANCZOS)))

    # estrategia 4: crop parte inferior (donde suele estar el QR en tickets)
    try:
        crop_box = (0, int(h * 0.6), w, h)
        bottom = orig.crop(crop_box)
        attempts.append(("crop_inferior_40%", bottom))
        attempts.append(("crop_inferior_40%_escalada_x2", bottom.resize((bottom.size[0] * 2, bottom.size[1] * 2), Image.LANCZOS)))
    except Exception:
        pass

    # estrategia 5: umbral adaptativo (mediante OpenCV), añadimos como imagen PIL
    try:
        gray = pil_to_cv_gray(orig)
        th = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY, 25, 10)
        attempts.append(("umbral_adaptativo", Image.fromarray(th)))
    except Exception:
        pass

    # probar cada intento y para cada rotación
    tried_methods = []
    for name, img in attempts:
        for ang in [0, 90, 180, 270]:
            try:
                ip = img.rotate(ang, expand=True) if ang != 0 else img
                datos = leer_con_pyzbar(ip)
                tried_methods.append(f"pyzbar:{name}:rot{ang}")
                if datos:
                    return datos
            except Exception as e:
                print(f"ERR_PYZBAR:{name}:rot{ang}:{e}", file=sys.stderr)

    # Si pyzbar no detectó, probar OpenCV detector sobre la imagen original
    try:
        datos = leer_con_opencv(path)
        tried_methods.append(f"opencv:original")
        if datos:
            return datos
    except Exception as e:
        print(f"ERR_OPENCV:original:{e}", file=sys.stderr)

    # intentar OpenCV sobre escalada temporal en memoria
    try:
        orig_scaled = orig.resize((orig.size[0] * 2, orig.size[1] * 2), Image.LANCZOS)
        arr = np.array(orig_scaled.convert('RGB'))
        datos = leer_con_opencv(arr)
        tried_methods.append('opencv:escalada_x2')
        if datos:
            return datos
    except Exception as e:
        print(f"ERR_OPENCV:escalada:{e}", file=sys.stderr)

    # Si llegamos aquí, no se detectó nada
    print("No se encontró ningún código QR en las estrategias probadas.")
    # también loguear métodos probados a stderr para depuración
    print("TIPS: intenta recortar cerca del QR o usar mayor resolución.", file=sys.stderr)
    print("TRIED_METHODS:" + ",".join(tried_methods), file=sys.stderr)
    return []


def main():
    # obtener ruta desde argumento si está presente
    img_path = DEFAULT_IMG_PATH
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if arg and os.path.exists(arg):
            img_path = arg
        else:
            # si el argumento no existe, informamos por stderr pero seguimos con default si existe
            print(f"ARG_NO_EXISTS:{arg}", file=sys.stderr)

    if not os.path.exists(img_path):
        print(f"ERROR_FILE_NOT_FOUND:{img_path}", file=sys.stderr)
        print("No se encontró ningún código QR, intenta recortar la imagen o usar mayor resolución.")
        return

    datos = intentar_varias_estrategias(img_path)
    if datos:
        for d in datos:
            print(d)
    else:
        # ya se imprimió un mensaje explicativo dentro de intentar_varias_estrategias
        pass


if __name__ == '__main__':
    main()
