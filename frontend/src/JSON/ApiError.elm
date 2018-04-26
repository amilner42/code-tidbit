module JSON.ApiError exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Models.ApiError exposing (..)


{-| Turns an errorCode integer from the backend to it's respective ApiError.
-}
fromErrorCode : Int -> ApiError
fromErrorCode errorCode =
    case errorCode of
        1 ->
            YouAreUnauthorized

        2 ->
            EmailAddressAlreadyRegistered

        3 ->
            NoAccountExistsForEmail

        4 ->
            IncorrectPasswordForEmail

        5 ->
            PhoneNumberAlreadyTaken

        6 ->
            InvalidMongoID

        7 ->
            InvalidEmail

        8 ->
            InvalidPassword

        9 ->
            InternalError

        10 ->
            PasswordDoesNotMatchConfirmPassword

        11 ->
            SnipbitEmptyRange

        12 ->
            SnipbitEmptyComment

        13 ->
            SnipbitNoHighlightedComments

        14 ->
            SnipbitEmptyCode

        15 ->
            SnipbitNoTags

        16 ->
            SnipbitEmptyTag

        17 ->
            SnipbitEmptyDescription

        18 ->
            SnipbitEmptyName

        19 ->
            SnipbitNameTooLong

        20 ->
            SnipbitInvalidLanguage

        21 ->
            InvalidName

        22 ->
            SnipbitDoesNotExist

        23 ->
            BigbitEmptyRange

        24 ->
            BigbitEmptyComment

        25 ->
            BigbitEmptyFilePath

        26 ->
            BigbitEmptyName

        27 ->
            BigbitNameTooLong

        28 ->
            BigbitEmptyDescription

        29 ->
            BigbitEmptyTag

        30 ->
            BigbitNoTags

        31 ->
            BigbitNoHighlightedComments

        32 ->
            BigbitInvalidLanguage

        33 ->
            BigbitDoesNotExist

        34 ->
            InvalidBio

        35 ->
            StoryNameEmpty

        36 ->
            StoryNameTooLong

        37 ->
            StoryDescriptionEmpty

        38 ->
            StoryDescriptionTooLong

        39 ->
            StoryInvalidTidbitType

        40 ->
            StoryEmptyTag

        41 ->
            StoryNoTags

        42 ->
            StoryDoesNotExist

        43 ->
            StoryEditorMustBeAuthor

        44 ->
            StoryAddingNonExistantTidbit

        45 ->
            SnipbitDescriptionTooLong

        46 ->
            BigbitDescriptionTooLong

        _ ->
            InternalError


{-| `ApiError` decoder.
-}
decoder : Decode.Decoder ApiError
decoder =
    let
        backendDecoder =
            decode BackendError
                |> required "message" Decode.string
                |> required "errorCode" Decode.int

        backendErrorToApiError { errorCode } =
            fromErrorCode errorCode
    in
    Decode.map backendErrorToApiError backendDecoder
