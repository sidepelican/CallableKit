import { CodableResult, CodableResult_JSON, CodableResult_decode } from "./OtherDependency/CodableResult.gen.js";
import { SubmitError } from "./SubmitError.gen.js";
import { IStubClient } from "./common.gen.js";
import { identity } from "./decode.gen.js";

export interface IAccountClient {
    signin(request: AccountSignin_Request): Promise<CodableResult<AccountSignin_Response, SubmitError<AccountSignin_Error>>>;
}

export const bindAccount = (stub: IStubClient): IAccountClient => {
    return {
        async signin(request: AccountSignin_Request): Promise<CodableResult<AccountSignin_Response, SubmitError<AccountSignin_Error>>> {
            const json = await stub.send(request, "Account/signin") as CodableResult_JSON<AccountSignin_Response, SubmitError<AccountSignin_Error>>;
            return CodableResult_decode(json, identity, identity);
        }
    };
};

export type AccountSignin = never;

export type AccountSignin_Request = {
    email: string;
    password: string;
};

export type AccountSignin_Response = {
    userName: string;
};

export type AccountSignin_Error = "email" | "password" | "emailOrPassword";
