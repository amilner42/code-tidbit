module JSON.ApiError exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
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
            SnipbitEmptyConclusion

        15 ->
            SnipbitEmptyIntroduction

        16 ->
            SnipbitEmptyCode

        17 ->
            SnipbitNoTags

        18 ->
            SnipbitEmptyTag

        19 ->
            SnipbitEmptyDescription

        20 ->
            SnipbitEmptyName

        21 ->
            SnipbitNameTooLong

        22 ->
            SnipbitInvalidLanguage

        23 ->
            InvalidName

        24 ->
            SnipbitDoesNotExist

        25 ->
            BigbitEmptyRange

        26 ->
            BigbitEmptyComment

        27 ->
            BigbitEmptyFilePath

        28 ->
            BigbitEmptyName

        29 ->
            BigbitNameTooLong

        30 ->
            BigbitEmptyDescription

        31 ->
            BigbitEmptyTag

        32 ->
            BigbitNoTags

        33 ->
            BigbitEmptyIntroduction

        34 ->
            BigbitEmptyConclusion

        35 ->
            BigbitNoHighlightedComments

        36 ->
            BigbitInvalidLanguage

        37 ->
            BigbitDoesNotExist

        38 ->
            InvalidBio

        39 ->
            StoryNameEmpty

        40 ->
            StoryNameTooLong

        41 ->
            StoryDescriptionEmpty

        42 ->
            StoryDescriptionTooLong

        43 ->
            StoryInvalidTidbitType

        44 ->
            StoryEmptyTag

        45 ->
            StoryNoTags

        46 ->
            StoryDoesNotExist

        47 ->
            StoryEditorMustBeAuthor

        48 ->
            StoryAddingNonExistantTidbit

        49 ->
            SnipbitDescriptionTooLong

        50 ->
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
