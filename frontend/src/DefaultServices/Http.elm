module DefaultServices.Http exposing (get, post)

import Http
import JSON.ApiError
import Json.Decode as Decode
import Json.Encode as Encode
import Models.ApiError as ApiError


{- This module is designed to be used with a backend which serves errors back, refer to Models.ApiError to see the
   format of expected errors.
-}


{-| In case of an http error, extracts the ApiError, otherwise extracts the body.
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

  - Set's `withCredentials` = `True`.

-}
get : String -> Decode.Decoder a -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
get url decoder onApiError onApiSuccess =
    let
        -- Get with credentials.
        get : String -> Decode.Decoder a -> Http.Request a
        get url decoder =
            Http.request
                { method = "GET"
                , headers = []
                , url = url
                , body = Http.emptyBody
                , expect = Http.expectJson decoder
                , timeout = Nothing
                , withCredentials = True
                }

        httpRequest =
            get url decoder
    in
    Http.send (handleHttpResult onApiError onApiSuccess) httpRequest


{-| A HTTP post request.

  - adds a JSON header
  - Set's `withCredentials` = `True`

-}
post : String -> Decode.Decoder a -> Encode.Value -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
post url decoder body onApiError onApiSuccess =
    let
        -- Post with credentials.
        post : String -> Http.Body -> Decode.Decoder a -> Http.Request a
        post url body decoder =
            Http.request
                { method = "POST"
                , headers = []
                , url = url
                , body = body
                , expect = Http.expectJson decoder
                , timeout = Nothing
                , withCredentials = True
                }

        httpRequest =
            post url (Http.jsonBody body) decoder
    in
    Http.send (handleHttpResult onApiError onApiSuccess) httpRequest
