# Trancanage Treuil Frema

Ce projet propose une nouvelle version durcie du système de trancanage développé par et pour l'AACM (Association Aéronautique de Coulommiers Meaux)

Les visuels et dossier d'industrialisation proposés ici ne représente qu'une partie du système global et plus particulièrement la partie régulation et pilotage des moteurs électriques. 

## Les éléments du design

Le système est composé d'une partie moteur-commande et d'un capteur magnétique déporté. Une partie assemblage mécanique permettant de mettre en mouvement les bras de guidage n'est pas traitée dans le cadre de ce dépot GIT.

### Le capteur magnétique

Le capteur magnétique permet de compter le nombre de tours de la bobine du treuil Frema. Un aimant est directement collé sur la transmission et passe devant le capteur à chaque tour. L'information est ensuite renvoyée au boitier moteur commande pour calculer et ajuster la régulation (position et vitesse).

![test](https://img.shields.io/badge/Statut-OK-brightgreen)

### Le boitier moteur-commande
La partie puissance composée d'un moteur électrique, d'un réducteur et d'une électronique associée est reliée au capteur magnétique.
Le boitier est directement collé sur le motoréducteur grâce à une pièce d'adaptation dont les plans sont disponibles dans ce dépôt.
A l'intérieur du boitier deux cartes électroniques se partagent le travail.  
Une __carte commande__ avec un microcontrôleur PIC, une interface RS232 et un capteur de position de l'axe moteur.
Une __carte de puissance__ avec un demi pont à base de transistor MOSFET, la generation des alimentations auxiliaires et des mesures courant/tensions.

![test](https://img.shields.io/badge/Statut-En_cours_de_validation-important)



## License

**Les travaux présentés ici sont sous la licence [Creative Commons Share-alike 4.0 International](http://creativecommons.org/licenses/by-sa/4.0/).**

Note : Il s'agit d'un résumé lisible par l'homme (et non d'un substitut) de [license](http://creativecommons.org/licenses/by-sa/4.0/legalcode).

