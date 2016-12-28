module Models.User
    exposing
        ( User
        , encoder
        , decoder
        , cacheDecoder
        , cacheEncoder
        , AuthUser
        , authEncoder
        )

import DefaultServices.Util exposing (justValueOrNull)
import Json.Decode as Decode exposing (field)
import Json.Encode as Encode


{-| The User type.
-}
type alias User =
    { email : String
    , password : Maybe (String)
    }


{-| The User `decoder`.
-}
decoder : Decode.Decoder User
decoder =
    Decode.map2 User
        (field "email" Decode.string)
        (Decode.maybe (field "password" Decode.string))


{-| The User `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder User
cacheDecoder =
    decoder


{-| The user `encoder`.
-}
encoder : User -> Encode.Value
encoder user =
    Encode.object
        [ ( "email", Encode.string user.email )
        , ( "password", justValueOrNull Encode.string user.password )
        ]


{-| The User `cacheEncoder`.
-}
cacheEncoder : User -> Encode.Value
cacheEncoder user =
    Encode.object
        [ ( "email", Encode.string user.email )
        , ( "password", Encode.null )
        ]


{-| For authentication we only send an email and password.
-}
type alias AuthUser =
    { email : String
    , password : String
    }


{-| Encodes the user for the initial authentication request (login/register).
-}
authEncoder : AuthUser -> Encode.Value
authEncoder authUser =
    Encode.object
        [ ( "email", Encode.string authUser.email )
        , ( "password", Encode.string authUser.password )
        ]
