# Trancannage Treuil Frema

Ce projet propose une nouvelle version durcie du système de trancannage développé par et pour l'AACM (Association Aéronautique de Coulommiers Meaux)

Les visuels et dossier d'industrialisation proposés ici ne représente qu'une partie du système global et plus particulièrement la partie régulation et pilotage des moteurs électriques. 

## Les éléments du design

Le système est composé d'une partie moteur-commande et d'un capteur magnétique déporté. Une partie assemblage mécanique permettant de mettre en mouvement les bras de guidage n'est pas traité dans le cadre de ce dépot GIT.

### Le capteur magnétique

Le capteur magnétique permet de compter le nombre de tour de la bobine du treuil Frema. Un aimant est directement collé sur la transmission et passe devant le capteur à chaque tour. L'information est ensuite renvoyé au boitier moteur commande pour calculer et ajuster la régulation (position et vitesse).

![test](https://img.shields.io/badge/Statut-OK-brightgreen)

### Le boitier moteur-commande
La partie puissance composée d'un moteur électrique, d'un réducteur et d'une électronique associée est relié au capteur magnétique.
Le boitier est directement collé sur le motoréducteur grâce à une pièce d'adaptation dont les plans sont disponible dans ce dépôt.
A l'intérieur du boitier deux cartes électroniques se partagent le travail.  
Une _carte commande_ avec un microcontrôleur PIC, une interface RS232 et des leds de statut.
Une carte de puissance avec un demi pont à base de transistor MOSFET et des mesures courant/tensions.

![test](https://img.shields.io/badge/Statut-En_cours_de_validation-important)



## License

[MIT](https://choosealicense.com/licenses/mit/)
