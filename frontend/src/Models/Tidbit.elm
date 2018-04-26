module Models.Tidbit exposing (..)

import Date as Date
import Elements.Simple.Editor exposing (Language)
import Models.Bigbit as BigbitModel
import Models.Route as Route
import Models.Snipbit as SnipbitModel
import Models.TidbitPointer as TidbitPointer


{-| All the different tidbit types.
-}
type Tidbit
    = Snipbit SnipbitModel.Snipbit
    | Bigbit BigbitModel.Bigbit


{-| Gets the name of a tidbit.
-}
getName : Tidbit -> String
getName tidbit =
    case tidbit of
        Snipbit { name } ->
            name

        Bigbit { name } ->
            name


{-| Gets the ID of a tidbit.
-}
getID : Tidbit -> String
getID tidbit =
    case tidbit of
        Snipbit { id } ->
            id

        Bigbit { id } ->
            id


{-| Gets the `likes` of a tidbit.
-}
getLikes : Tidbit -> Int
getLikes tidbit =
    case tidbit of
        Snipbit { likes } ->
            likes

        Bigbit { likes } ->
            likes


{-| Gets the date a tidbit was last modified.
-}
getLastModified : Tidbit -> Date.Date
getLastModified tidbit =
    case tidbit of
        Snipbit { lastModified } ->
            lastModified

        Bigbit { lastModified } ->
            lastModified


{-| Get's the languages.
-}
getLanguages : Tidbit -> List Language
getLanguages tidbit =
    case tidbit of
        Snipbit { language } ->
            [ language ]

        Bigbit { languages } ->
            languages


{-| Gets the route-base for viewing the tidbit, still requires the ID to become a full `Route`.
-}
getTidbitRoute : Maybe String -> Tidbit -> Route.Route
getTidbitRoute fromStoryID tidbit =
    case tidbit of
        Snipbit { id } ->
            Route.ViewSnipbitFramePage fromStoryID id 1

        Bigbit { id } ->
            Route.ViewBigbitIntroductionPage fromStoryID id Nothing


{-| Returns true if a tidbit is a snipbit.
-}
isSnipbit : Tidbit -> Bool
isSnipbit tidbit =
    case tidbit of
        Snipbit _ ->
            True

        _ ->
            False


{-| Returns true if a tidbit is a bigbit.
-}
isBigbit : Tidbit -> Bool
isBigbit tidbit =
    case tidbit of
        Bigbit _ ->
            True

        _ ->
            False


{-| Converts a tidbit to compressed-pointer form.
-}
compressTidbit : Tidbit -> TidbitPointer.TidbitPointer
compressTidbit tidbit =
    case tidbit of
        Snipbit { id } ->
            { tidbitType = TidbitPointer.Snipbit
            , targetID = id
            }

        Bigbit { id } ->
            { tidbitType = TidbitPointer.Bigbit
            , targetID = id
            }
