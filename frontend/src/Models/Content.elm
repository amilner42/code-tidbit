module Models.Content exposing (..)

import Models.Bigbit exposing (Bigbit)
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
