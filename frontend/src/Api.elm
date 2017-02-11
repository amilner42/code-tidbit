module Api
    exposing
        ( getAccount
        , getLogOut
        , getSnipbit
        , getBigbit
        , postLogin
        , postRegister
        , postCreateSnipbit
        , postCreateBigbit
        )

import Config exposing (apiBaseUrl)
import DefaultServices.Http as HttpService
import Json.Decode as Decode
import Json.Encode as Encode
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.Bigbit as Bigbit
import Models.CreateTidbitResponse as CreateTidbitResponse
import Models.Snipbit as Snipbit
import Models.User as User


{-| Helper for querying the API (GET), automatically adds the apiBaseUrl prefix.
-}
apiGet : String -> Decode.Decoder a -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
apiGet url =
    HttpService.get (apiBaseUrl ++ url)


{-| Helper for qeurying the API (POST), automatically adds the apiBaseUrl prefix.
-}
apiPost : String -> Decode.Decoder a -> Encode.Value -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
apiPost url =
    HttpService.post (apiBaseUrl ++ url)


{-| Gets the users account, or an error if unauthenticated.
-}
getAccount : (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
getAccount =
    apiGet "account" User.decoder


{-| Queries the API to log the user out, which should send a response to delete
the cookies.
-}
getLogOut : (ApiError.ApiError -> b) -> (BasicResponse.BasicResponse -> b) -> Cmd b
getLogOut =
    apiGet "logOut" BasicResponse.decoder


{-| For adding a slash in a URL.
-}
(:/:) : String -> String -> String
(:/:) str1 str2 =
    str1 ++ "/" ++ str2


{-| Get's a snipbit.
-}
getSnipbit : String -> (ApiError.ApiError -> b) -> (Snipbit.Snipbit -> b) -> Cmd b
getSnipbit snipbitID =
    apiGet ("snipbits" :/: snipbitID) Snipbit.snipbitDecoder


{-| Get's a bigbit.
-}
getBigbit : String -> (ApiError.ApiError -> b) -> (Bigbit.Bigbit -> b) -> Cmd b
getBigbit bigbitID =
    apiGet ("bigbits" :/: bigbitID) Bigbit.bigbitDecoder


{-| Logs user in and returns the user, unless invalid credentials.
-}
postLogin : User.UserForLogin -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
postLogin user =
    apiPost "login" User.decoder (User.userLoginEncoder user)


{-| Registers the user and returns the user, unless invalid new credentials.
-}
postRegister : User.UserForRegistration -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
postRegister user =
    apiPost "register" User.decoder (User.userRegisterEncoder user)


{-| Creates a new snipbit.
-}
postCreateSnipbit : Snipbit.SnipbitForPublication -> (ApiError.ApiError -> b) -> (CreateTidbitResponse.CreateTidbitResponse -> b) -> Cmd b
postCreateSnipbit snipbit =
    apiPost
        "snipbits"
        CreateTidbitResponse.createTidbitResponseDecoder
        (Snipbit.snipbitForPublicationEncoder snipbit)


{-| Creates a new bigbit.
-}
postCreateBigbit : Bigbit.BigbitForPublication -> (ApiError.ApiError -> b) -> (CreateTidbitResponse.CreateTidbitResponse -> b) -> Cmd b
postCreateBigbit bigbit =
    apiPost
        "bigbits"
        CreateTidbitResponse.createTidbitResponseDecoder
        (Bigbit.bigbitForPublicationEncoder bigbit)
