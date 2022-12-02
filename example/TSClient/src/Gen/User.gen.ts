export type User = {
    id: User_ID;
    name: string;
};

export type User_ID = string & {
    User_ID: never;
};
