module Models.User exposing (..)

{-| -}


{-| The User type.
-}
type alias User =
    { id : String
    , name : String
    , email : String
    , password : Maybe String
    , bio : String
    }


{-| For registration we only send an email, password, and name.
-}
type alias UserForRegistration =
    { name : String
    , email : String
    , password : String
    }


{-| For login we only send an email and password.
-}
type alias UserForLogin =
    { email : String
    , password : String
    }


{-| For updating a user through the API.
-}
type alias UserUpdateRecord =
    { name : Maybe String
    , bio : Maybe String
    }


{-| Gets the theme for a user.

TODO Implement function

-}
getTheme : Maybe User -> String
getTheme maybeUser =
    ""


{-| This record-update represents 0 changes to the user.
-}
defaultUserUpdateRecord : UserUpdateRecord
defaultUserUpdateRecord =
    { name = Nothing
    , bio = Nothing
    }
