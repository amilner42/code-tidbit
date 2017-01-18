module Models.ApiError exposing (ApiError(..), decoder, humanReadable)

import Json.Decode as Decode exposing (field)


{- COPIED from the backend, needs to stay up to date with the backend!

   export enum errorCodes {
     youAreUnauthorized = 1,
     emailAddressAlreadyRegistered,
     noAccountExistsForEmail,
     incorrectPasswordForEmail,
     phoneNumberAlreadyTaken,
     invalidMongoID,
     invalidEmail,
     invalidPassword,
     internalError,                    // For errors that are not handleable
     passwordDoesNotMatchConfirmPassword
   }
-}


{-| An error from the backend converted to a union.
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
    | BasicTidbitEmptyRange
    | BasicTidbitEmptyComment
    | BasicTidbitNoHighlightedComments
    | BasicTidbitEmptyConclusion
    | BasicTidbitEmptyIntroduction
    | BasicTidbitEmptyCode
    | BasicTidbitNoTags
    | BasicTidbitEmptyTag
    | BasicTidbitEmptyDescription
    | BasicTidbitEmptyName
    | BasicTidbitNameTooLong
    | BasicTidbitInvalidLanguage


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

        BasicTidbitEmptyRange ->
            "You must have a range selected for each frame!"

        BasicTidbitEmptyComment ->
            "You must have an explanatory comment on each frame!"

        BasicTidbitNoHighlightedComments ->
            "You must have at least one explanatory frame!"

        BasicTidbitEmptyConclusion ->
            "You must have a conclusion!"

        BasicTidbitEmptyIntroduction ->
            "You must have a introduction!"

        BasicTidbitEmptyCode ->
            "You must have code!"

        BasicTidbitNoTags ->
            "You must have at least one tag!"

        BasicTidbitEmptyTag ->
            "You must have no empty tags!"

        BasicTidbitEmptyDescription ->
            "You must have a description!"

        BasicTidbitEmptyName ->
            "You must have a name!"

        BasicTidbitNameTooLong ->
            "Name entered is too long! "

        BasicTidbitInvalidLanguage ->
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
            BasicTidbitEmptyRange

        12 ->
            BasicTidbitEmptyComment

        13 ->
            BasicTidbitNoHighlightedComments

        14 ->
            BasicTidbitEmptyConclusion

        15 ->
            BasicTidbitEmptyIntroduction

        16 ->
            BasicTidbitEmptyCode

        17 ->
            BasicTidbitNoTags

        18 ->
            BasicTidbitEmptyTag

        19 ->
            BasicTidbitEmptyDescription

        20 ->
            BasicTidbitEmptyName

        21 ->
            BasicTidbitNameTooLong

        22 ->
            BasicTidbitInvalidLanguage

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
