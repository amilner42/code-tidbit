module Pages.Browse.Init exposing (..)

import Pages.Browse.Model exposing (..)


{-| `Browse` init.
-}
init : Model
init =
    { content = Nothing
    , pageNumber = 1
    , noMoreContent = False
    , searchQuery = ""
    , showNewContentMessage = True
    , showAdvancedSearchOptions = False
    , contentFilterSnipbits = True
    , contentFilterBigbits = True
    , contentFilterStories = True
    , contentFilterIncludeEmptyStories = False
    }
