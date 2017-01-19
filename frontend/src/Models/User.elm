module Models.User
    exposing
        ( User
        , UserForRegistration
        , UserForLogin
        , cacheDecoder
        , cacheEncoder
        , decoder
        , userLoginEncoder
        , userRegisterEncoder
        )

import DefaultServices.Util exposing (justValueOrNull)
import Json.Decode as Decode exposing (field)
import Json.Encode as Encode


{-| The User type.
-}
type alias User =
    { name : String
    , email : String
    , password : Maybe (String)
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


{-| The User `decoder`.
-}
decoder : Decode.Decoder User
decoder =
    cacheDecoder


{-| The User `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder User
cacheDecoder =
    Decode.map3 User
        (field "name" Decode.string)
        (field "email" Decode.string)
        (Decode.maybe (field "password" Decode.string))


{-| The User `cacheEncoder`.
-}
cacheEncoder : User -> Encode.Value
cacheEncoder user =
    Encode.object
        [ ( "name", Encode.string user.name )
        , ( "email", Encode.string user.email )
        , ( "password", Encode.null )
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
