import { Array_decode, Array_encode, TagRecord } from "../../common.js";

export type InputFieldError<E> = {
    name: E;
    message: string;
} & TagRecord<"InputFieldError", [E]>;

export type InputFieldError_JSON<E_JSON> = {
    name: E_JSON;
    message: string;
};

export function InputFieldError_decode<E, E_JSON>(json: InputFieldError_JSON<E_JSON>, E_decode: (json: E_JSON) => E): InputFieldError<E> {
    const name = E_decode(json.name);
    const message = json.message;
    return {
        name: name,
        message: message
    };
}

export function InputFieldError_encode<E, E_JSON>(entity: InputFieldError<E>, E_encode: (entity: E) => E_JSON): InputFieldError_JSON<E_JSON> {
    const name = E_encode(entity.name);
    const message = entity.message;
    return {
        name: name,
        message: message
    };
}

export type SubmitError<E> = {
    errors: InputFieldError<E>[];
} & TagRecord<"SubmitError", [E]>;

export type SubmitError_JSON<E_JSON> = {
    errors: InputFieldError_JSON<E_JSON>[];
};

export function SubmitError_decode<E, E_JSON>(json: SubmitError_JSON<E_JSON>, E_decode: (json: E_JSON) => E): SubmitError<E> {
    const errors = Array_decode<InputFieldError<E>, InputFieldError_JSON<E_JSON>>(json.errors, (json: InputFieldError_JSON<E_JSON>): InputFieldError<E> => {
        return InputFieldError_decode<E, E_JSON>(json, E_decode);
    });
    return {
        errors: errors
    };
}

export function SubmitError_encode<E, E_JSON>(entity: SubmitError<E>, E_encode: (entity: E) => E_JSON): SubmitError_JSON<E_JSON> {
    const errors = Array_encode<InputFieldError<E>, InputFieldError_JSON<E_JSON>>(entity.errors, (entity: InputFieldError<E>): InputFieldError_JSON<E_JSON> => {
        return InputFieldError_encode<E, E_JSON>(entity, E_encode);
    });
    return {
        errors: errors
    };
}
