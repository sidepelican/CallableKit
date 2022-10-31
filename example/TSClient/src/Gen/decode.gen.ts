export function identity<T>(json: T): T {
    return json;
}

export function OptionalField_decode<T, U>(json: T | undefined, T_decode: (json: T) => U): U | undefined {
    if (json === undefined) return undefined;
    return T_decode(json);
}

export function Optional_decode<T, U>(json: T | null, T_decode: (json: T) => U): U | null {
    if (json === null) return null;
    return T_decode(json);
}

export function Array_decode<T, U>(json: T[], T_decode: (json: T) => U): U[] {
    return json.map(T_decode);
}

export function Dictionary_decode<T, U>(json: { [key: string]: T; }, T_decode: (json: T) => U): { [key: string]: U; } {
    const result: { [key: string]: U; } = {};
    for (const k in json) {
        if (json.hasOwnProperty(k)) {
            result[k] = T_decode(json[k]);
        }
    }
    return result;
}
