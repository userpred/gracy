from io import BytesIO
from PIL import Image
from fastapi import UploadFile
from string import ascii_letters
from random import choice
from faker import Faker
from faker.providers import internet


def get_fake():
    fake = Faker('ko_KR')
    fake.add_provider(internet)
    return fake


def snake2pascal(string: str):
    return (
        string
        .replace("_", " ")
        .title()
        .replace(" ", "")
    )


def pascal2snake(string: str):
    return ''.join(
        word.title() for word in string.split('_')
    )


def get_random_id(length=15):
    string_pool = ascii_letters + "0123456789"
    rand_string = [choice(string_pool) for _ in range(length)]
    return "".join(rand_string)


def remove_none_value(document: dict):
    keys = list(document.keys())
    for key in keys:
        if document[key] is None:
            del document[key]
    return document


def extract_ext(origin_filename: str):
    return origin_filename.rsplit('.', 1)[1].lower()


def file_to_img(file: UploadFile) -> Image:
    bytes_io = BytesIO(file.read())
    return Image.open(bytes_io)


def img_to_bytesio(img: Image) -> BytesIO:
    img_file = BytesIO()
    img.save(img_file, format=img.format)
    img_file.seek(0)
    return img_file


def resize_img(img: Image, width: int, height: int):
    w, h = img.size
    if width < w or height < h:
        resized_img = img.resize((width, height))
        resized_img.format = img.format
        return resized_img
    else:
        return img


def tokenizer(
    name: str, address: str
):
    names = [name, name.replace(' ', '')]
    address = address[2:]
    tokens = []

    # Name Tokenizing
    for name in names:
        name_length = len(name)
        for i in range(name_length - 1):
            for j in range(i + 1, name_length):
                tokens.append(name[i: j + 1])

        # Address Tokenizing
        address_length = len(address)
        for i in range(address_length - 1):
            for j in range(i + 1, address_length):
                tokens.append(address[i: j + 1])

        # Overlap Token Removing
        tokens = list(set(tokens))

    return tokens
