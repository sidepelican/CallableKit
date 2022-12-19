export type GenericIDz<T> = string & {
    GenericIDz: never;
};

export type GenericIDz_JSON<T_JSON> = string;

export function GenericIDz_decode<T, T_JSON>(json: GenericIDz_JSON<T_JSON>, T_decode: (json: T_JSON) => T): GenericIDz<T> {
    return json as GenericIDz<T>;
}
