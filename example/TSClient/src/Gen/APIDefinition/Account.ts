import { TagRecord } from "../common.js";

export type AccountSignin = never;

export type AccountSignin_Request = {
    email: string;
    password: string;
} & TagRecord<"AccountSignin_Request">;

export type AccountSignin_Response = {
    userName: string;
} & TagRecord<"AccountSignin_Response">;

export type AccountSignin_Error = "email" | "password" | "emailOrPassword";
