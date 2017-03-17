module Models.User exposing (..)

import DefaultServices.Util exposing (justValueOrNull)
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)


{-| The User type.
-}
type alias User =
    { id : String
    , name : String
    , email : String
    , password : Maybe (String)
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


{-| The User `decoder`.
-}
decoder : Decode.Decoder User
decoder =
    cacheDecoder


{-| The User `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder User
cacheDecoder =
    decode User
        |> required "id" Decode.string
        |> required "name" Decode.string
        |> required "email" Decode.string
        |> required "password" (Decode.maybe Decode.string)
        |> required "bio" Decode.string


{-| The User `cacheEncoder`.
-}
cacheEncoder : User -> Encode.Value
cacheEncoder user =
    Encode.object
        [ ( "id", Encode.string user.id )
        , ( "name", Encode.string user.name )
        , ( "email", Encode.string user.email )
        , ( "password", Encode.null )
        , ( "bio", Encode.string user.bio )
        ]


{-| Encodes the user for registration request.
-}
userRegisterEncoder : UserForRegistration -> Encode.Value
userRegisterEncoder registerUser =
    Encode.object
        [ ( "name", Encode.string registerUser.name )
        , ( "email", Encode.string registerUser.email )
        , ( "password", Encode.string registerUser.password )
        ]


{-| Encodes the user for a login request.
-}
userLoginEncoder : UserForLogin -> Encode.Value
userLoginEncoder loginUser =
    Encode.object
        [ ( "email", Encode.string loginUser.email )
        , ( "password", Encode.string loginUser.password )
        ]


{-| Gets the theme for a user.

TODO Implement function
-}
getTheme : Maybe User -> String
getTheme maybeUser =
    ""


{-| Encodes the UserUpdateRecord.
-}
userUpdateRecordEncoder : UserUpdateRecord -> Encode.Value
userUpdateRecordEncoder userUpdateRecord =
    Encode.object
        [ ( "name", justValueOrNull Encode.string userUpdateRecord.name )
        , ( "bio", justValueOrNull Encode.string userUpdateRecord.bio )
        ]


{-| This record-update represents 0 changes to the user.
-}
defaultUserUpdateRecord : UserUpdateRecord
defaultUserUpdateRecord =
    { name = Nothing
    , bio = Nothing
    }
