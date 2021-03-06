module Models.Content exposing (..)

import Elements.Simple.Editor exposing (Language)
import Models.Bigbit exposing (Bigbit)
import Models.Route as Route
import Models.Snipbit exposing (Snipbit)
import Models.Story exposing (Story)
import Models.Tidbit as TidbitModel


{-| Content represents all of the possible user-created content.
-}
type Content
    = Snipbit Snipbit
    | Bigbit Bigbit
    | Story Story


{-| Get's the name of content.
-}
getName : Content -> String
getName content =
    case content of
        Snipbit { name } ->
            name

        Bigbit { name } ->
            name

        Story { name } ->
            name


{-| Get's the description of content.
-}
getDescription : Content -> String
getDescription content =
    case content of
        Snipbit { description } ->
            description

        Bigbit { description } ->
            description

        Story { description } ->
            description


{-| Get's the languages of content.
-}
getLanguages : Content -> List Language
getLanguages content =
    case content of
        Snipbit { language } ->
            [ language ]

        Bigbit { languages } ->
            languages

        Story { languages } ->
            languages


{-| Get's the `authorEmail` of the content.
-}
getAuthorEmail : Content -> String
getAuthorEmail content =
    case content of
        Snipbit { authorEmail } ->
            authorEmail

        Bigbit { authorEmail } ->
            authorEmail

        Story { authorEmail } ->
            authorEmail


{-| Get's the `likes` of the content.
-}
getLikes : Content -> Int
getLikes content =
    case content of
        Snipbit { likes } ->
            likes

        Bigbit { likes } ->
            likes

        Story { likes } ->
            likes


{-| Returns true if the content is a snipbit.
-}
isSnipbit : Content -> Bool
isSnipbit content =
    case content of
        Snipbit _ ->
            True

        _ ->
            False


{-| Returns true if the content is a bigbit.
-}
isBigbit : Content -> Bool
isBigbit content =
    case content of
        Bigbit _ ->
            True

        _ ->
            False


{-| Returns true if the content is a story.
-}
isStory : Content -> Bool
isStory content =
    case content of
        Story _ ->
            True

        _ ->
            False


{-| For converting a tidbit into the more broad union `Content`.
-}
fromTidbit : TidbitModel.Tidbit -> Content
fromTidbit tidbit =
    case tidbit of
        TidbitModel.Snipbit snipbit ->
            Snipbit snipbit

        TidbitModel.Bigbit bigbit ->
            Bigbit bigbit


{-| Get's the route to navigate to if you want to view certain content. Pass the storyID if it is from the context of
a story.
-}
getRouteForViewing : Content -> Maybe String -> Route.Route
getRouteForViewing content maybeStoryID =
    case content of
        Snipbit { id } ->
            Route.ViewSnipbitFramePage maybeStoryID id 1

        Bigbit { id } ->
            Route.ViewBigbitFramePage maybeStoryID id 1 Nothing

        Story { id } ->
            Route.ViewStoryPage id
