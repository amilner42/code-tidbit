module DefaultServices.Http exposing (get, post)

import Http
import Json.Decode as Decode
import Json.Encode as Encode
import JSON.ApiError
import Models.ApiError as ApiError


{- NOTE This module is designed to be used with a backend which serves errors
   back, refer to Models.ApiError to see the format of expected errors.
-}


{-| In case of an http error, extracts the ApiError, otherwise extracts the
body.
-}
handleHttpResult : (ApiError.ApiError -> b) -> (a -> b) -> Result Http.Error a -> b
handleHttpResult onApiError onApiSuccess httpResult =
    let
        convertToApiError httpError =
            case httpError of
                Http.BadUrl _ ->
                    ApiError.InternalError

                Http.NetworkError ->
                    ApiError.RawNetworkError

                Http.Timeout ->
                    ApiError.RawTimeout

                Http.BadStatus { body } ->
                    case Decode.decodeString JSON.ApiError.decoder body of
                        Ok apiError ->
                            apiError

                        Err errorMessage ->
                            ApiError.InternalError

                Http.BadPayload _ _ ->
                    ApiError.UnexpectedPayload
    in
        case httpResult of
            Ok expectedResult ->
                onApiSuccess expectedResult

            Err httpError ->
                onApiError (convertToApiError httpError)


{-| A HTTP get request.
-}
get : String -> Decode.Decoder a -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
get url decoder onApiError onApiSuccess =
    let
        httpRequest =
            Http.get url decoder
    in
        Http.send (handleHttpResult onApiError onApiSuccess) httpRequest


{-| A HTTP post request, adds a JSON header.
-}
post : String -> Decode.Decoder a -> Encode.Value -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
post url decoder body onApiError onApiSuccess =
    let
        httpRequest =
            Http.post url (Http.jsonBody body) decoder
    in
        Http.send (handleHttpResult onApiError onApiSuccess) httpRequest
