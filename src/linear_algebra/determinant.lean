/-
Copyright (c) 2018 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau, Chris Hughes, Casper Putz
-/
import data.matrix.basic
import group_theory.perm.sign

/-!
# Determinants

## Main definitions

* The determinant of a square matrix
* The `(i,j)`-th cofactor of a square matrix

## Main statements

* The determinant is mulitplicative
* The cofactor expansion or Laplace expansion of the determinant

## Tags
determinant, cofactor, Laplace expansion

-/

universes u v
open equiv equiv.perm finset function

namespace matrix

variables {n : Type u} [fintype n] [decidable_eq n] {R : Type v} [comm_ring R]

local notation `ε` σ:max := ((sign σ : ℤ ) : R)

definition det (M : matrix n n R) : R :=
univ.sum (λ (σ : perm n), ε σ * univ.prod (λ i, M (σ i) i))

@[simp] lemma det_diagonal {d : n → R} : det (diagonal d) = univ.prod d :=
begin
  refine (finset.sum_eq_single 1 _ _).trans _,
  { intros σ h1 h2,
    cases not_forall.1 (mt (equiv.ext _ _) h2) with x h3,
    convert ring.mul_zero _,
    apply finset.prod_eq_zero,
    { change x ∈ _, simp },
    exact if_neg h3 },
  { simp },
  { simp }
end

@[simp] lemma det_zero (h : nonempty n) : det (0 : matrix n n R) = 0 :=
by rw [← diagonal_zero, det_diagonal, finset.prod_const, ← fintype.card,
  zero_pow (fintype.card_pos_iff.2 h)]

@[simp] lemma det_one : det (1 : matrix n n R) = 1 :=
by rw [← diagonal_one]; simp [-diagonal_one]

lemma det_mul_aux {M N : matrix n n R} {p : n → n} (H : ¬bijective p) :
  univ.sum (λ σ : perm n, (ε σ) * (univ.prod (λ x, M (σ x) (p x) * N (p x) x))) = 0 :=
begin
  obtain ⟨i, j, hpij, hij⟩ : ∃ i j, p i = p j ∧ i ≠ j,
  { rw [← fintype.injective_iff_bijective, injective] at H,
    push_neg at H,
    exact H },
  exact sum_involution
    (λ σ _, σ * swap i j)
    (λ σ _,
      have ∀ a, p (swap i j a) = p a := λ a, by simp only [swap_apply_def]; split_ifs; cc,
      have univ.prod (λ x, M (σ x) (p x)) = univ.prod (λ x, M ((σ * swap i j) x) (p x)),
        from prod_bij (λ a _, swap i j a) (λ _ _, mem_univ _) (by simp [this])
          (λ _ _ _ _ h, (swap i j).injective h)
          (λ b _, ⟨swap i j b, mem_univ _, by simp⟩),
      by simp [sign_mul, this, sign_swap hij, prod_mul_distrib])
    (λ σ _ _ h, hij (σ.injective $ by conv {to_lhs, rw ← h}; simp))
    (λ _ _, mem_univ _)
    (λ _ _, equiv.ext _ _ $ by simp)
end

@[simp] lemma det_mul (M N : matrix n n R) : det (M * N) = det M * det N :=
calc det (M * N) = univ.sum (λ σ : perm n, (univ.pi (λ a, univ)).sum
    (λ (p : Π (a : n), a ∈ univ → n), ε σ *
    univ.attach.prod (λ i, M (σ i.1) (p i.1 (mem_univ _)) * N (p i.1 (mem_univ _)) i.1))) :
  by simp only [det, mul_val', prod_sum, mul_sum]
... = univ.sum (λ σ : perm n, univ.sum
    (λ p : n → n, ε σ * univ.prod (λ i, M (σ i) (p i) * N (p i) i))) :
  sum_congr rfl (λ σ _, sum_bij
    (λ f h i, f i (mem_univ _)) (λ _ _, mem_univ _)
    (by simp) (by simp [funext_iff]) (λ b _, ⟨λ i hi, b i, by simp⟩))
... = univ.sum (λ p : n → n, univ.sum
    (λ σ : perm n, ε σ * univ.prod (λ i, M (σ i) (p i) * N (p i) i))) :
  finset.sum_comm
... = ((@univ (n → n) _).filter bijective).sum (λ p : n → n, univ.sum
    (λ σ : perm n, ε σ * univ.prod (λ i, M (σ i) (p i) * N (p i) i))) :
  eq.symm $ sum_subset (filter_subset _)
    (λ f _ hbij, det_mul_aux $ by simpa using hbij)
... = (@univ (perm n) _).sum (λ τ, univ.sum
    (λ σ : perm n, ε σ * univ.prod (λ i, M (σ i) (τ i) * N (τ i) i))) :
  sum_bij (λ p h, equiv.of_bijective (mem_filter.1 h).2) (λ _ _, mem_univ _)
    (λ _ _, rfl) (λ _ _ _ _ h, by injection h)
    (λ b _, ⟨b, mem_filter.2 ⟨mem_univ _, b.bijective⟩, eq_of_to_fun_eq rfl⟩)
... = univ.sum (λ σ : perm n, univ.sum (λ τ : perm n,
    (univ.prod (λ i, N (σ i) i) * ε τ) * univ.prod (λ j, M (τ j) (σ j)))) :
  by simp [mul_sum, det, mul_comm, mul_left_comm, prod_mul_distrib, mul_assoc]
... = univ.sum (λ σ : perm n, univ.sum (λ τ : perm n,
    (univ.prod (λ i, N (σ i) i) * (ε σ * ε τ)) *
    univ.prod (λ i, M (τ i) i))) :
  sum_congr rfl (λ σ _, sum_bij (λ τ _, τ * σ⁻¹) (λ _ _, mem_univ _)
    (λ τ _,
      have univ.prod (λ j, M (τ j) (σ j)) = univ.prod (λ j, M ((τ * σ⁻¹) j) j),
        by rw prod_univ_perm σ⁻¹; simp [mul_apply],
      have h : ε σ * ε (τ * σ⁻¹) = ε τ :=
        calc ε σ * ε (τ * σ⁻¹) = ε ((τ * σ⁻¹) * σ) :
          by rw [mul_comm, sign_mul (τ * σ⁻¹)]; simp [sign_mul]
        ... = ε τ : by simp,
      by rw h; simp [this, mul_comm, mul_assoc, mul_left_comm])
    (λ _ _ _ _, (mul_right_inj _).1) (λ τ _, ⟨τ * σ, by simp⟩))
... = det M * det N : by simp [det, mul_assoc, mul_sum, mul_comm, mul_left_comm]

instance : is_monoid_hom (det : matrix n n R → R) :=
{ map_one := det_one,
  map_mul := det_mul }

section cofactor

/-- The (i,j)-th cofactor of M is (upto sign) the determinant of the submatrix of M obtained by
removing its i-th row and j-th column. -/
def cofactor (i j : n) (M : matrix n n R) : R :=
ε (swap i j) * (det $ minor M (swap i j ∘ subtype.val) (subtype.val : {k // k ≠ j} → n))

lemma cofactor_expansion_aux (M : matrix n n R) (i j : n) :
  univ.sum (λ σ : {σ : perm n // σ j = i}, ε σ.val * univ.prod (λ l, M (σ l) l)) =
  M i j * cofactor i j M :=
have hsσ : ∀ (σ : {σ : perm n // σ j = i}) l, (swap i j * σ.val) l ≠ l → l ≠ j,
  { intros σ k, contrapose!, intro h, rw [h, mul_apply, σ.2], exact swap_apply_left _ _ },
have hσ : ∀ (σ : { σ : perm n // σ j = i }) l, l ≠ j ↔ (swap i j * σ) l ≠ j,
  from λ σ l, by { rw [mul_apply, not_iff_not], change l = j ↔ ⇑(swap i j) (σ.val l) = j,
  exact ⟨λ h, by { rw [h, σ.2], exact swap_apply_left i j },
    λ h, σ.val.injective $ (swap i j).injective $ eq.symm $
        by { rw [h, σ.2], exact swap_apply_left i j }⟩ },
calc univ.sum (λ σ : { σ : perm n // σ j = i }, ε σ.val * univ.prod (λ l, M (σ.val l) l))
    = M i j * univ.sum (λ σ : { σ : perm n // σ j = i }, ε σ.val *
        (erase univ j).prod (λ l, M (swap i j $ swap i j $ σ l) l)) :
  by { rw [mul_sum],
    refine sum_congr rfl (λ σ _, _),
    rw [←insert_erase (mem_univ j), prod_insert (not_mem_erase _ _), ←mul_assoc, mul_comm _ (M _ _),
      mul_assoc, insert_erase (mem_univ j), σ.2], congr, finish [swap_swap_apply] }
... = M i j * ε (swap i j) * univ.sum (λ τ : perm { k // k ≠ j }, ε τ * univ.prod (λ l, M (swap i j $ τ l) l)) :
  by { rw [mul_assoc, @mul_sum _ _ _ _ (ε (swap i j))],
    refine congr_arg _ (sum_bij (λ σ _, subtype_perm (swap i j * σ.val) (hσ σ)) (λ _ _, mem_univ _)
      (λ σ _,
        by { rw_mod_cast [sign_subtype_perm _ _ (hsσ _), sign_mul, ←mul_assoc, ←units.coe_mul,
          ←mul_assoc, ←sign_mul, equiv.swap_mul_self, sign_one, one_mul],
        exact congr_arg _ (prod_bij (λ l hl, ⟨l, (mem_erase.mp hl).1⟩) (λ _ _, mem_univ _)
          (λ _ _, rfl) (λ _ _ _ _, congr_arg subtype.val)
          (λ l _, ⟨l, mem_erase.mpr ⟨l.2, mem_univ _⟩, eq.symm (subtype.eta _ _)⟩)) })
      (λ σ₁ σ₂ _ _ h, by { rw [subtype.ext],
        simpa [of_subtype_subtype_perm _ (hsσ _)] using congr_arg of_subtype h })
      (λ τ _, ⟨⟨swap i j * of_subtype τ, by { change equiv.swap i j (of_subtype τ j) = i,
          finish [of_subtype_apply_of_not_mem, swap_apply_left] }⟩,
        mem_univ _,
        by { change τ = subtype_perm (swap i j * swap i j * of_subtype τ) _,
          simp only [equiv.swap_mul_self, one_mul, subtype_perm_of_subtype] } ⟩)) }
... = M i j * cofactor i j M : mul_assoc _ _ _

/-- The deteminant of M can be expanded as the sum over a the i-th row times the corresponding
cofactor for each element. -/
lemma cofactor_expansion (M : matrix n n R) (i : n) :
  det M = univ.sum (λ j, M i j * cofactor i j M) :=
calc det M = (finset.sigma univ (λ j, @univ {σ : perm n // σ j = i} _)).sum
    (λ σ : Σ (j : n), {σ : perm n // σ j = i}, ε σ.2.val * univ.prod (λ l, M (σ.2 l) l)) :
  eq.symm (sum_bij (λ σ _, σ.snd.val) (λ _ _, mem_univ _) (λ _ _, rfl)
    (λ σ1 σ2 _ _ h, by { have h1 : σ1.fst = σ2.fst,
        { apply equiv.injective σ1.2.1, rw [σ1.snd.property, h, σ2.snd.property] },
      refine sigma.eq h1 (subtype.val_injective _),
      rw ←h, congr, { rw h1 }, exact eq_rec_heq _ _ } )
    (λ σ _, ⟨sigma.mk (σ.inv_fun i) ⟨σ, σ.right_inv i⟩ , mem_univ _, rfl⟩))
... = univ.sum (λ j, univ.sum (λ σ : {σ : perm n // σ j = i}, ε σ.val * univ.prod (λ l, M (σ l) l))) : sum_sigma
... = univ.sum (λ j, M i j * cofactor i j M) : sum_congr rfl (λ j _, cofactor_expansion_aux M i j)

end cofactor

end matrix
