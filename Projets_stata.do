/////pour ue meilleur vue des résultats; il faut tout excécuter d'un coup et aller voir le fichier excel à la fin 

* importation des donnée du compte github
use https://raw.githubusercontent.com/123wade/Projet_stata/main/ehcvm_welfare_SEN2021.dta

*suppression des variables inutiles pour notre analyse
drop country dali dnal dtot grappe hactiv7j hactiv12m hage halfa halfa2 hbranch hdiploma heduc hhandig hhid hnation hreligion hsectins menage vague year

*le fichier excel pour resumer les resultats obtenus
putexcel set "analyse_de_la_pauverete.xlsx", replace
*creation des variables poids individuel(pind) de l'indicatrice(ind)
capture drop pind ind pauv0 P0 P1 P2
gen pind = hhweight*hhsize
gen ind = (pcexp<zref)

*tot des ponderation 
quietly summarize pind
local tot = r(sum)

*calcul de P0
* creation de la variable pauv0 pour calcul des wi((zref-yi)/zref)^alpha*ind avec alpha = 0
gen pauv0 = ind*pind
*Calcul de la somme des pauv0 stock en local
quietly summarize pauv0 /* NB: quietely permet de faire le summarize sans l'afficher*/
local a = r(sum)
* enfin le la divion de la somme des pauv0 par la somme des poids pour avoir le taux de pauvrete national 
local b = r(sum)
display "La pauverete nationale est de : " `a'/`b'*100 "%"
gen P0 = `a'/`tot'

*calcul de profondeur de la pauvrete
*creation de la variable pauv1 pour calcul des wi((zref-yi)/zref)^alpha*ind avec alpha = 1
capture drop pauv1
gen pauv1 = ind*pind*((zref-pcexp)/zref)
*Calcul de la somme des pauv0 stock en local
quietly summarize pauv1
local a = r(sum)
*somme des poids 
* enfin le la divion de la somme des pauv0 par la somme des poids pour avoir le taux de pauvrete national 
display "La profondeur de la pauverete nationale est de : " `a'/`b'*100 "%"
gen P1 = `a'/`tot'

*calcul de severite de la pauvrete
*creation de la variable pauv2 pour calcul des wi((zref-yi)/zref)^alpha*ind avec alpha = 2
capture drop pauv2
gen pauv2 = ind*pind*((zref-pcexp)/zref)^2
*Calcul de la somme des pauv2 stock en local
quietly summarize pauv2 
local a = r(sum) 
*enfin le la divion de la somme des pauv0 par la somme des poids pour avoir le taux de pauvrete national  
display "La severite de la pauverete nationale est de : " `a'/`b'*100 "%"
gen P2 = `a'/`tot'
*** vers excel 
putexcel set "analyse_de_la_pauverete.xlsx", sheet("N-MR-R") modify
putexcel A1:B1, merge
putexcel A1 = "Pauverete nationale", bold
putexcel A3 = "Indices", bold
putexcel B3 = "Taux",bold
putexcel A4 = "P0"
putexcel B4 = P0
putexcel A5 = "P1"
putexcel B5 = P1
putexcel A6 = "P2"
putexcel B6 = P2

* calcul de pauverete par milieu de residence 
** save  "C:\Users\USER\Desktop\projet stata\urbain", replace
matrix pauvMR =J(2,4,.) /* on cree une matrice de 2 ligne et 3 colonnes pour stocker les differente valeurs prise dans la boucle*/
forvalues i = 1/2 {
    * Part dans la population
    quietly summarize pind if milieu==`i'
    local pop = r(sum)
    matrix pauvMR[`i',1] = (`pop'/`tot')*100
    * P0, P1 et P2
    forvalues k = 0/2 {
        quietly summarize pauv`k' if milieu==`i'
        local a = r(sum)
        matrix pauvMR[`i',`k'+2] = (`a'/`pop')*100
    }
}
* nom de colonne et ligne de la matrice pauvMR
matrix colname pauvMR = "Part dans la population" P0 P1 P2
matrix rowname pauvMR = Urbain Rural
matrix list pauvMR
putexcel set "analyse_de_la_pauverete.xlsx", sheet("N-MR-R") modify
putexcel A8:E8, merge
putexcel A8 = "Indices de pauverete selon le milieu de residence", bold
putexcel A10 = "Milieu", bold
putexcel A10 = matrix(pauvMR), names

** numlabel ensuites tab pour voir les observation et les labels  
numlabel, add
tab region

* calcul du taux de pauverete selon la region 
matrix pauvR = J(14,4,.)
forvalues i = 1/14 {
    * Part dans la population
    quietly summarize pind if region==`i'
    local pop = r(sum)
    matrix pauvR[`i',1] = (`pop'/`tot')*100
    * P0, P1 et P2
    forvalues k = 0/2 {
        quietly summarize pauv`k' if region==`i'
        local a = r(sum)
        matrix pauvR[`i',`k'+2] = (`a'/`pop')*100
    }
}

matrix colnames pauvR = "Part dans la population" P0 P1 P2
matrix rownames pauvR = DAKAR ZIGUINCOR DIOURBEL SAINT-LOUIS TAMBACOUNDA KAOLACK THIES LOUGA FATICK KOLDA MATAM KAFFRINE KEDOUGOU SEDHIOU
matrix list pauvR
putexcel set "analyse_de_la_pauverete.xlsx", sheet("N-MR-R") modify
putexcel G1:K1, merge
putexcel G1 = "Indices de pauverete selon la region", bold
putexcel G3= "Regions",bold
putexcel G3 = matrix(pauvR),names

*taux de pauverete par region et par milieu de residence
matrix pauvRMR  =J(14, 7,.)
forvalues i = 1/14 {
    forvalues j= 1/2{
    * Part dans la population
    quietly summarize pind if region==`i' & milieu==`j' 
    local pop = r(sum)
    matrix pauvRMR[`i',1] = (`pop'/`tot')*100
    * P0, P1 et P2
    forvalues k = 0/2 {
       quietly sum pauv`k' if region==`i' & milieu==`j'
        local a = r(sum)
        matrix pauvRMR[`i',2 + 2*`k' + (`j'-1)] = (`a'/`pop')*100
    }
}
}


matrix colnames pauvRMR = "Part dans la population" UrbainP0 RuralP0 UrbainP1 RuralP1 UrbainP2 RuralP2
matrix rownames pauvRMR = DAKAR ZIGUINCOR DIOURBEL SAINT-LOUIS TAMBACOUNDA KAOLACK THIES LOUGA FATICK KOLDA MATAM KAFFRINE KEDOUGOU SEDHIOU
matrix list pauvRMR 
putexcel set "analyse_de_la_pauverete.xlsx", sheet("RMR") modify
putexcel A1:H1, merge
putexcel A1 = "Indices de pauverete selon la region et le milieu de residence", bold
putexcel A3 = "Regions", bold
putexcel A3 = matrix(pauvRMR),names

*******
matrix pauvSP = J(10,4,.)
forvalues i = 1/10 {
    * Part dans la population
    quietly summarize pind if hcsp==`i'
    local pop = r(sum)
    matrix pauvSP[`i',1] = (`pop'/`tot')*100
    * P0, P1 et P2
    forvalues k = 0/2 {
        quietly summarize pauv`k' if hcsp==`i'
        local a = r(sum)
        matrix pauvSP[`i',`k'+2] = (`a'/`pop')*100
    }
}

*noms des colonnes des matrices et noms des lignes 
matrix colnames pauvSP = "Part dans la population" P0 P1 P2
matrix rownames pauvSP = "Cadre supérieur" "Cadre moyen/agent de maîtrise"  "Ouvrier ou employé qualifié"  "Ouvrier ou employé non qualifié"   "Manœuvre, aide ménagère"  "Stagiaire ou Apprenti rénuméré"  "Stagiaire/Apprenti non rénuméré" "Travail_Familial_contri_pour_u" "Travailleur pour compte propre"   "Patron"
** affichage du tableau sous stata
matrix list pauvSP
** enregistrement sur le fichier excel sur la feuille 
putexcel set "analyse_de_la_pauverete.xlsx", sheet("SP-SEX-SM") modify
putexcel A1:F1, merge
putexcel A1 = "Indices de pauverete selon la region et le milieu de residence",bold
putexcel A3 = "Regions", bold
putexcel A3 = matrix(pauvSP),names
putexcel A11 = "Travailleur Familial contribuant pour u"

* calcul de taux de pauverete selon le sex 
matrix pauvSex = J(2,4,.)
forvalues i = 1/2 {
    * Part dans la population
    quietly summarize pind if hgender==`i'
    local pop = r(sum)
    matrix pauvSex[`i',1] = (`pop'/`tot')*100
    * P0, P1 et P2
    forvalues k = 0/2 {
        quietly summarize pauv`k' if hgender==`i'
        local a = r(sum)
        matrix pauvSex[`i',`k'+2] = (`a'/`pop')*100
    }
}


** enregistrement sur le fichier excel sur la feuille 
matrix colnames pauvSex = "Part dans la population" P0 P1 P2
matrix rownames pauvSex = Homme Femme
matrix list pauvSex
putexcel set "analyse_de_la_pauverete.xlsx", sheet("SP-SEX-SM") modify
putexcel H1:L1, merge
putexcel H1 = "Indices de pauverete selon le sexe", bold
putexcel H3 = "Sexe", bold
putexcel H3 = matrix(pauvSex),names

* calcul de pauverete selon la situation matrimoniale
matrix pauvSM = J(7,4,.)
* Total pondéré
forvalues i = 1/7 {
    * Part dans la population
    quietly summarize pind if hmstat==`i'
    local pop = r(sum)
    matrix pauvSM[`i',1] = (`pop'/`tot')*100
    * P0, P1 et P2
    forvalues k = 0/2 {
        quietly summarize pauv`k' if hmstat==`i'
        local a = r(sum)
        matrix pauvSM[`i',`k'+2] = (`a'/`b')*100
    }
}
matrix colnames pauvSM = "Part dans la population" P0 P1 P2
matrix rownames pauvSM = ///
"Célibataire" ///
"Marié(e) monogame" "Marié(e) polygame" "Union libre" "Veuf(ve)" "Divorcé(e)" "Séparé(e)"
matrix list pauvSM
putexcel set "analyse_de_la_pauverete.xlsx", sheet("SP-SEX-SM") modify
putexcel H8:L8, merge
putexcel H8 = "Indices de pauverete selon la situation matrimoniale",bold 
putexcel H10 = "Situation matrimoniale",bold
putexcel H10 = matrix(pauvSM),names, 