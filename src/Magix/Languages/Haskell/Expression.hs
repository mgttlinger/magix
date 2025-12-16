-- |
-- Module      :  Magix.Languages.Haskell.Expression
-- Description :  Build Haskell command lines
-- Copyright   :  2024 Dominik Schrempf
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  experimental
-- Portability :  portable
--
-- Creation date: Fri Oct 18 13:36:32 2024.
module Magix.Languages.Haskell.Expression
  ( getHaskellReplacements,
  )
where

import Data.Text (unwords, unlines)
import Magix.Languages.Common.Expression 
import Magix.Languages.Haskell.Directives (HaskellDirectives (..))
import Prelude hiding (readFile, unwords, unlines)

--haskellFlakeExpr :: FlakeRef -> Text
--haskellFlakeExpr (p, pn) = pack "(builtins.getFlake \"" <> p <> pack "\").packages.${builtins.currentSystem}." <> fromMaybe "default" pn

getHaskellReplacements :: HaskellDirectives -> [Replacement]
getHaskellReplacements (HaskellDirectives ps fs) =
  let (packs, flakes) = partitionFlakes ps in
  [ ("__HASKELL_PACKAGES__", unwords $ packs <> (fst . flakeOverride <$> flakes)),
    ("__FLAKES__", unlines $ flakeInput <$> flakes),
    ("__OVERRIDES__", overrides $ flakeOverride <$> flakes),
    ("__GHC_FLAGS__", unwords fs)
  ]
