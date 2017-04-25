module Models.ApiError exposing (..)

{-| -}


{-| An error from the backend converted to a union.

NOTE: This must stay up to date with the backend, refer to types.ts to see backend errors.
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
    | BigbitDoesNotExist
    | InvalidBio
    | StoryNameEmpty
    | StoryNameTooLong
    | StoryDescriptionEmpty
    | StoryDescriptionTooLong
    | StoryInvalidTidbitType
    | StoryEmptyTag
    | StoryNoTags
    | StoryDoesNotExist
    | StoryEditorMustBeAuthor
    | StoryAddingNonExistantTidbit
    | SnipbitDescriptionTooLong
    | BigbitDescriptionTooLong


{-| An error from the backend still in Json form.
-}
type alias BackendError =
    { message : String
    , errorCode : Int
    }


{-| Gives a nice human readable representation of the `apiError`, this is intended to be read by the user. Some of the
errors below will never face the users (if they use the webapp), but just for the sake of it I give all errors a human
readable message, in case they decide the API directly for instance.
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
            "Snipbit names are limited to 50 characters!"

        SnipbitInvalidLanguage ->
            "Language selected was not valid!"

        InvalidName ->
            "The name you entered is not valid!"

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
            "Bigbit names are limited to 50 characters!"

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

        BigbitDoesNotExist ->
            "The bigbit you are looking for does not exist!"

        InvalidBio ->
            "The bio you entered is not valid!"

        StoryNameEmpty ->
            "You cannot have empty story names!"

        StoryNameTooLong ->
            "Story names are limited to 50 characters!"

        StoryDescriptionEmpty ->
            "You cannot have an empty description for your story!"

        StoryDescriptionTooLong ->
            "Story descriptions are limited to 300 characters!"

        StoryInvalidTidbitType ->
            "That is not a valid tidbit type, refer to the API for valid tidbit types!"

        StoryEmptyTag ->
            "You cannot have empty tags!"

        StoryNoTags ->
            "Stories must have at least a single tag!"

        StoryDoesNotExist ->
            "No story exists with that ID!"

        StoryEditorMustBeAuthor ->
            "You can only edit your own stories!"

        StoryAddingNonExistantTidbit ->
            "You are adding a non-existant tidbit!"

        SnipbitDescriptionTooLong ->
            "Snipbit descriptions are limited to 300 characters!"

        BigbitDescriptionTooLong ->
            "Bigbit descriptions are limited to 300 characters!"
