import { Array_decode, Array_encode } from "./decode.gen.js";

export type InputFieldError<E> = {
    name: E;
    message: string;
};

export type InputFieldError_JSON<E_JSON> = {
    name: E_JSON;
    message: string;
};

export function InputFieldError_decode<E, E_JSON>(json: InputFieldError_JSON<E_JSON>, E_decode: (json: E_JSON) => E): InputFieldError<E> {
    return {
        name: E_decode(json.name),
        message: json.message
    };
}

export function InputFieldError_encode<E, E_JSON>(entity: InputFieldError<E>, E_encode: (entity: E) => E_JSON): InputFieldError_JSON<E_JSON> {
    return {
        name: E_encode(entity.name),
        message: entity.message
    };
}

export type SubmitError<E> = {
    errors: InputFieldError<E>[];
};

export type SubmitError_JSON<E_JSON> = {
    errors: InputFieldError_JSON<E_JSON>[];
};

export function SubmitError_decode<E, E_JSON>(json: SubmitError_JSON<E_JSON>, E_decode: (json: E_JSON) => E): SubmitError<E> {
    return {
        errors: Array_decode(json.errors, (json: InputFieldError_JSON<E_JSON>): InputFieldError<E> => {
            return InputFieldError_decode(json, E_decode);
        })
    };
}

export function SubmitError_encode<E, E_JSON>(entity: SubmitError<E>, E_encode: (entity: E) => E_JSON): SubmitError_JSON<E_JSON> {
    return {
        errors: Array_encode(entity.errors, (entity: InputFieldError<E>): InputFieldError_JSON<E_JSON> => {
            return InputFieldError_encode(entity, E_encode);
        })
    };
}
