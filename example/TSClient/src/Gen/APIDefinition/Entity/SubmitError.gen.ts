import { Array_decode, Array_encode, TagRecord } from "../../common.gen.js";

export type InputFieldError<E> = {
    name: E;
    message: string;
} & TagRecord<"InputFieldError", [E]>;

export type InputFieldError$JSON<E$JSON> = {
    name: E$JSON;
    message: string;
};

export function InputFieldError_decode<E, E$JSON>(json: InputFieldError$JSON<E$JSON>, E_decode: (json: E$JSON) => E): InputFieldError<E> {
    const name = E_decode(json.name);
    const message = json.message;
    return {
        name: name,
        message: message
    };
}

export function InputFieldError_encode<E, E$JSON>(entity: InputFieldError<E>, E_encode: (entity: E) => E$JSON): InputFieldError$JSON<E$JSON> {
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

export type SubmitError$JSON<E$JSON> = {
    errors: InputFieldError$JSON<E$JSON>[];
};

export function SubmitError_decode<E, E$JSON>(json: SubmitError$JSON<E$JSON>, E_decode: (json: E$JSON) => E): SubmitError<E> {
    const errors = Array_decode<InputFieldError<E>, InputFieldError$JSON<E$JSON>>(json.errors, (json: InputFieldError$JSON<E$JSON>): InputFieldError<E> => {
        return InputFieldError_decode<E, E$JSON>(json, E_decode);
    });
    return {
        errors: errors
    };
}

export function SubmitError_encode<E, E$JSON>(entity: SubmitError<E>, E_encode: (entity: E) => E$JSON): SubmitError$JSON<E$JSON> {
    const errors = Array_encode<InputFieldError<E>, InputFieldError$JSON<E$JSON>>(entity.errors, (entity: InputFieldError<E>): InputFieldError$JSON<E$JSON> => {
        return InputFieldError_encode<E, E$JSON>(entity, E_encode);
    });
    return {
        errors: errors
    };
}
