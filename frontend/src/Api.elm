module Api
    exposing
        ( getAccount
        , getLogOut
        , postLogin
        , postRegister
        , postBasicCodeTidbit
        )

import Config exposing (apiBaseUrl)
import DefaultServices.Http as HttpService
import Json.Decode as Decode
import Json.Encode as Encode
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.BasicTidbit as BasicTidbit
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


{-| Creates a new basic tidbit.
-}
postBasicCodeTidbit : BasicTidbit.BasicTidbit -> (ApiError.ApiError -> b) -> (BasicResponse.BasicResponse -> b) -> Cmd b
postBasicCodeTidbit basicTidbit =
    apiPost
        "create/basicTidbit"
        BasicResponse.decoder
        (BasicTidbit.basicTidbitEncoder basicTidbit)
