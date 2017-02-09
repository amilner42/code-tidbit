module Models.ApiError exposing (ApiError(..), decoder, humanReadable)

import Json.Decode as Decode exposing (field)


{-| An error from the backend converted to a union.

NOTE: This must stay up to date with the backend, refer to types.ts to see
backend errors.
-}
type ApiError
    = UnexpectedPayload
    | RawTimeout
    | RawNetworkError
    | YouAreUnauthorized
    | EmailAddressAlreadyRegistered
    | NoAccountExistsForEmail
    | IncorrectPasswordForEmail
    | PhoneNumberAlreadyTaken
    | InvalidMongoID
    | InvalidEmail
    | InvalidPassword
    | InternalError
    | PasswordDoesNotMatchConfirmPassword
    | SnipbitEmptyRange
    | SnipbitEmptyComment
    | SnipbitNoHighlightedComments
    | SnipbitEmptyConclusion
    | SnipbitEmptyIntroduction
    | SnipbitEmptyCode
    | SnipbitNoTags
    | SnipbitEmptyTag
    | SnipbitEmptyDescription
    | SnipbitEmptyName
    | SnipbitNameTooLong
    | SnipbitInvalidLanguage
    | InvalidName
    | SnipbitDoesNotExist
    | BigbitEmptyRange
    | BigbitEmptyComment
    | BigbitEmptyFilePath
    | BigbitEmptyName
    | BigbitNameTooLong
    | BigbitEmptyDescription
    | BigbitEmptyTag
    | BigbitNoTags
    | BigbitEmptyIntroduction
    | BigbitEmptyConclusion
    | BigbitNoHighlightedComments
    | BigbitInvalidLanguage


{-| An error from the backend still in Json form.
-}
type alias BackendError =
    { message : String
    , errorCode : Int
    }


{-| Gives a nice human readable representation of the `apiError`, this is
intended to be read by the user. Some of the errors below will never face the
users (if they use the webapp), but just for the sake of it I give all errors
a human readable message, in case they decide the API directly for instance.
-}
humanReadable : ApiError -> String
humanReadable apiError =
    case apiError of
        UnexpectedPayload ->
            "Unexpected payload recieved"

        RawTimeout ->
            "Ooo something went wrong, try again!"

        RawNetworkError ->
            "You seem to be disconnected from the internet!"

        YouAreUnauthorized ->
            "You are unauthorized!"

        EmailAddressAlreadyRegistered ->
            "Email already registered!"

        NoAccountExistsForEmail ->
            "That email is unregistered!"

        IncorrectPasswordForEmail ->
            "Incorrect password!"

        PhoneNumberAlreadyTaken ->
            "Phone number already registered"

        InvalidMongoID ->
            "Invalid MongoID"

        InvalidEmail ->
            "That's not even a valid email!"

        InvalidPassword ->
            "That password is not strong enough!"

        InternalError ->
            "Internal error...try again later!"

        PasswordDoesNotMatchConfirmPassword ->
            "Passwords do not match!"

        SnipbitEmptyRange ->
            "You must have a range selected for each frame!"

        SnipbitEmptyComment ->
            "You must have an explanatory comment on each frame!"

        SnipbitNoHighlightedComments ->
            "You must have at least one explanatory frame!"

        SnipbitEmptyConclusion ->
            "You must have a conclusion!"

        SnipbitEmptyIntroduction ->
            "You must have a introduction!"

        SnipbitEmptyCode ->
            "You must have code!"

        SnipbitNoTags ->
            "You must have at least one tag!"

        SnipbitEmptyTag ->
            "You must have no empty tags!"

        SnipbitEmptyDescription ->
            "You must have a description!"

        SnipbitEmptyName ->
            "You must have a name!"

        SnipbitNameTooLong ->
            "Name entered is too long! "

        SnipbitInvalidLanguage ->
            "Language selected was not valid!"

        InvalidName ->
            "Please enter your preffered name"

        SnipbitDoesNotExist ->
            "Snipbit does not exist!"

        BigbitEmptyRange ->
            "You must have a range selected for each frame!"

        BigbitEmptyComment ->
            "You must have an explanatory comment on each frame!"

        BigbitEmptyFilePath ->
            "Every frame must point to a file!"

        BigbitEmptyName ->
            "You must name your bigbit!"

        BigbitNameTooLong ->
            "Your bigbit name is too long!"

        BigbitEmptyDescription ->
            "Your bigbit must have a description!"

        BigbitEmptyTag ->
            "You cannot have empty tags in your bigbit!"

        BigbitNoTags ->
            "Your bigbit must have at least one tag!"

        BigbitEmptyIntroduction ->
            "Your bigbit must have an introduction!"

        BigbitEmptyConclusion ->
            "Your bigbit must have a conclusion!"

        BigbitNoHighlightedComments ->
            "You must have at least one frame!"

        BigbitInvalidLanguage ->
            "Language selected was not valid!"


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

        _ ->
            InternalError


{-| Decodes the API error from the backend error.
-}
decoder : Decode.Decoder ApiError
decoder =
    let
        backendDecoder =
            Decode.map2 BackendError
                (field "message" Decode.string)
                (field "errorCode" Decode.int)

        backendErrorToApiError { errorCode } =
            fromErrorCode errorCode
    in
        Decode.map backendErrorToApiError backendDecoder
