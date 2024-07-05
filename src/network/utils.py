def get_status_colour(status: int) -> str:
    status_str = str(status)

    # NOTE: I tried to get this to work using properties and QSS but could not get the QLabel to be
    # re-drawn so the colour never changed. Hence why I am setting this in python:
    if status_str[0] == "1":
        bg_color = "#514779"
    elif status_str[0] == "2":
        bg_color = "#3B6118"
    elif status_str[0] == "3":
        bg_color = "#205A6D"
    elif status_str[0] == "4":
        bg_color = "#7A4C15"
    elif status_str[0] == "5":
        bg_color = "#7A3435"
    else:
        bg_color = ""

    return bg_color


def get_status_colour_bright(status: int) -> str:
    status_str = str(status)

    # NOTE: I tried to get this to work using properties and QSS but could not get the QLabel to be
    # re-drawn so the colour never changed. Hence why I am setting this in python:
    if status_str[0] == "1":
        bg_color = "#7d69cb"
    elif status_str[0] == "2":
        bg_color = "#59a210"
    elif status_str[0] == "3":
        bg_color = "#1c90b4"
    elif status_str[0] == "4":
        bg_color = "#d07502"
    elif status_str[0] == "5":
        bg_color = "#d04444"
    else:
        bg_color = ""

    return bg_color


def get_method_colour(method: str) -> str:
    # NOTE: I tried to get this to work using properties and QSS but could not get the QLabel to be
    # re-drawn so the colour never changed. Hence why I am setting this in python:
    if method == "GET":
        bg_color = "#7FB144"
    elif method == "POST":
        bg_color = "#63AFCE"
    elif method == "PATCH":
        bg_color = "#E3D958"
    elif method == "PUT":
        bg_color = "#D48E3C"
    elif method == "DELETE":
        bg_color = "#D85D3D"
    elif method == "OPTIONS":
        bg_color = "#9A8DE5"
    elif method == "HEAD":
        bg_color = "#9A8DE5"
    else:
        bg_color = "#9A8DE5"

    return bg_color
