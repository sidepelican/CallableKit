export type CodableResult<T, E> = {
    kind: "success";
    success: {
        _0: T;
    };
} | {
    kind: "failure";
    failure: {
        _0: E;
    };
};

export type CodableResult_JSON<T_JSON, E_JSON> = {
    success: {
        _0: T_JSON;
    };
} | {
    failure: {
        _0: E_JSON;
    };
};

export function CodableResult_decode<
    T,
    E,
    T_JSON,
    E_JSON
>(json: CodableResult_JSON<T_JSON, E_JSON>, T_decode: (json: T_JSON) => T, E_decode: (json: E_JSON) => E): CodableResult<T, E> {
    if ("success" in json) {
        const j = json.success;
        return {
            kind: "success",
            success: {
                _0: T_decode(j._0)
            }
        };
    } else if ("failure" in json) {
        const j = json.failure;
        return {
            kind: "failure",
            failure: {
                _0: E_decode(j._0)
            }
        };
    } else {
        throw new Error("unknown kind");
    }
}
