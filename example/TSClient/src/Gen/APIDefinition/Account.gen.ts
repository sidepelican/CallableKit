import { IStubClient } from "../CallableKit.gen.js";
import { CodableResult, CodableResult_JSON, CodableResult_decode } from "../OtherDependency/CodableResult.gen.js";
import { TagRecord, identity } from "../common.gen.js";
import { SubmitError } from "./Entity/SubmitError.gen.js";

export interface IAccountClient {
    signin(request: AccountSignin_Request): Promise<CodableResult<AccountSignin_Response, SubmitError<AccountSignin_Error>>>;
}

export const bindAccount = (stub: IStubClient): IAccountClient => {
    return {
        async signin(request: AccountSignin_Request): Promise<CodableResult<AccountSignin_Response, SubmitError<AccountSignin_Error>>> {
            const json = await stub.send(request, "Account/signin") as CodableResult_JSON<AccountSignin_Response, SubmitError<AccountSignin_Error>>;
            return CodableResult_decode<
                AccountSignin_Response,
                AccountSignin_Response,
                SubmitError<AccountSignin_Error>,
                SubmitError<AccountSignin_Error>
            >(json, identity, identity);
        }
    };
};

export type AccountSignin = never;

export type AccountSignin_Request = {
    email: string;
    password: string;
} & TagRecord<"AccountSignin_Request">;

export type AccountSignin_Response = {
    userName: string;
} & TagRecord<"AccountSignin_Response">;

export type AccountSignin_Error = "email" | "password" | "emailOrPassword";
