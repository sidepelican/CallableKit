import { CodableResult, CodableResult_JSON, CodableResult_decode } from "./CodableResult.gen.js";
import { IRawClient } from "./common.gen.js";
import {
    Array_decode,
    OptionalField_decode,
    Optional_decode,
    identity
} from "./decode.gen.js";

export interface IAccountClient {
    signin(request: AccountSignin_Request): Promise<CodableResult<AccountSignin_Response, SubmitError<AccountSignin_Error>>>;
}

class AccountClient implements IAccountClient {
    rawClient: IRawClient;

    constructor(rawClient: IRawClient) {
        this.rawClient = rawClient;
    }

    async signin(request: AccountSignin_Request): Promise<CodableResult<AccountSignin_Response, SubmitError<AccountSignin_Error>>> {
        const json = await this.rawClient.fetch(request, "Account/signin") as CodableResult_JSON<AccountSignin_Response, SubmitError_JSON<AccountSignin_Error>>;
        return CodableResult_decode(json, identity, (json: SubmitError_JSON<AccountSignin_Error>): SubmitError<AccountSignin_Error> => {
            return SubmitError_decode(json, identity);
        });
    }
}

export const buildAccountClient = (raw: IRawClient): IAccountClient => new AccountClient(raw);

export type EchoHelloRequest = {
    name: string;
};

export type EchoHelloResponse = {
    message: string;
};

export type TestComplexType = never;

export type TestComplexType_K<T> = {
    x: T;
};

export type TestComplexType_K_JSON<T_JSON> = {
    x: T_JSON;
};

export function TestComplexType_K_decode<T, T_JSON>(json: TestComplexType_K_JSON<T_JSON>, T_decode: (json: T_JSON) => T): TestComplexType_K<T> {
    return {
        x: T_decode(json.x)
    };
}

export type TestComplexType_E<T> = {
    kind: "k";
    k: {
        _0: TestComplexType_K<T>;
    };
} | {
    kind: "i";
    i: {
        _0: number;
    };
} | {
    kind: "n";
    n: {};
};

export type TestComplexType_E_JSON<T_JSON> = {
    k: {
        _0: TestComplexType_K_JSON<T_JSON>;
    };
} | {
    i: {
        _0: number;
    };
} | {
    n: {};
};

export function TestComplexType_E_decode<T, T_JSON>(json: TestComplexType_E_JSON<T_JSON>, T_decode: (json: T_JSON) => T): TestComplexType_E<T> {
    if ("k" in json) {
        const j = json.k;
        return {
            kind: "k",
            k: {
                _0: TestComplexType_K_decode(j._0, T_decode)
            }
        };
    } else if ("i" in json) {
        const j = json.i;
        return {
            kind: "i",
            i: {
                _0: j._0
            }
        };
    } else if ("n" in json) {
        return {
            kind: "n",
            n: {}
        };
    } else {
        throw new Error("unknown kind");
    }
}

export type TestComplexType_L = {
    x: string;
};

export type TestComplexType_Request = {
    a?: TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]>;
};

export type TestComplexType_Request_JSON = {
    a?: TestComplexType_K_JSON<(TestComplexType_E_JSON<TestComplexType_L> | null)[]>;
};

export function TestComplexType_Request_decode(json: TestComplexType_Request_JSON): TestComplexType_Request {
    return {
        a: OptionalField_decode(json.a, (json: TestComplexType_K_JSON<(TestComplexType_E_JSON<TestComplexType_L> | null)[]>): TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]> => {
            return TestComplexType_K_decode(json, (json: (TestComplexType_E_JSON<TestComplexType_L> | null)[]): (TestComplexType_E<TestComplexType_L> | null)[] => {
                return Array_decode(json, (json: TestComplexType_E_JSON<TestComplexType_L> | null): TestComplexType_E<TestComplexType_L> | null => {
                    return Optional_decode(json, (json: TestComplexType_E_JSON<TestComplexType_L>): TestComplexType_E<TestComplexType_L> => {
                        return TestComplexType_E_decode(json, identity);
                    });
                });
            });
        })
    };
}

export type TestComplexType_Response = {
    a?: TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]>;
};

export type TestComplexType_Response_JSON = {
    a?: TestComplexType_K_JSON<(TestComplexType_E_JSON<TestComplexType_L> | null)[]>;
};

export function TestComplexType_Response_decode(json: TestComplexType_Response_JSON): TestComplexType_Response {
    return {
        a: OptionalField_decode(json.a, (json: TestComplexType_K_JSON<(TestComplexType_E_JSON<TestComplexType_L> | null)[]>): TestComplexType_K<(TestComplexType_E<TestComplexType_L> | null)[]> => {
            return TestComplexType_K_decode(json, (json: (TestComplexType_E_JSON<TestComplexType_L> | null)[]): (TestComplexType_E<TestComplexType_L> | null)[] => {
                return Array_decode(json, (json: TestComplexType_E_JSON<TestComplexType_L> | null): TestComplexType_E<TestComplexType_L> | null => {
                    return Optional_decode(json, (json: TestComplexType_E_JSON<TestComplexType_L>): TestComplexType_E<TestComplexType_L> => {
                        return TestComplexType_E_decode(json, identity);
                    });
                });
            });
        })
    };
}

export type AccountSignin = never;

export type AccountSignin_Request = {
    email: string;
    password: string;
};

export type AccountSignin_Response = {
    userName: string;
};

export type AccountSignin_Error = "email" | "password" | "emailOrPassword";

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
