-- |
-- Module      :  Magix.Languages.Python.Expression
-- Description :  Build Python command lines
-- Copyright   :  2024 Dominik Schrempf
-- License     :  GPL-3.0-or-later
--
-- Maintainer  :  dominik.schrempf@gmail.com
-- Stability   :  experimental
-- Portability :  portable
--
-- Creation date: Fri Oct 18 13:36:32 2024.
module Magix.Languages.Python.Expression
  ( getPythonReplacements,
  )
where

import Data.Text (unwords)
import Magix.Languages.Common.Expression 
import Magix.Languages.Python.Directives (PythonDirectives (..))
import Prelude hiding (unwords)

--python3FlakeExpr :: FlakeRef -> Text
--python3FlakeExpr (p, pn) = pack "((builtins.getFlake \"" <> p <> pack "\").outputs.packages.${builtins.currentSystem} { python3 = super.python3; })." <> fromMaybe "default" pn

getPythonReplacements :: PythonDirectives -> [Replacement]
getPythonReplacements (PythonDirectives ps) =
  let (packs, overs) = partitionFlakes ps in
  [ ("__PYTHON_PACKAGES__", unwords packs),
    ("__OVERRIDES__", overrides $ flakeOverride <$> overs)
  ]
