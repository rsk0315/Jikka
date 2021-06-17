{-# LANGUAGE LambdaCase #-}

module Jikka.RestrictedPython.Util where

import Jikka.Common.Alpha
import Jikka.RestrictedPython.Language.Expr

genType :: MonadAlpha m => m Type
genType = do
  i <- nextCounter
  return $ VarTy (TypeName ('$' : show i))

freeTyVars :: Type -> [TypeName]
freeTyVars = \case
  VarTy x -> [x]
  IntTy -> []
  BoolTy -> []
  ListTy t -> freeTyVars t
  TupleTy ts -> concat $ mapM freeTyVars ts
  CallableTy ts ret -> concat $ mapM freeTyVars (ret : ts)
