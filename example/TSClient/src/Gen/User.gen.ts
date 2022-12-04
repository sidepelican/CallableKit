export type User = {
    id: User_ID;
    name: string;
};

export type User_JSON = {
    id: User_ID_JSON;
    name: string;
};

export function User_decode(json: User_JSON): User {
    return {
        id: User_ID_decode(json.id),
        name: json.name
    };
}

export type User_ID = string & {
    User_ID: never;
};

export type User_ID_JSON = string;

export function User_ID_decode(json: User_ID_JSON): User_ID {
    return json as User_ID;
}
