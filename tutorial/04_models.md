---
title: "Marine Species Distribution Models"
author: "Mostly ChatGPT"
---


## Models

Species distribution modeling (SDM) involves various statistical and machine learning techniques to predict the spatial distribution of species based on environmental variables. The classic SDM model takes the form:

Probability of observation at location x = $p_x$
Probability of absence at location x = $1-p_x$

$p_x$ is some, perhaps complex, function of the values of the variables at location x. The goal is to find the best function that explains the observations and absences.

Some of the main models used for SDMs include:

1. **Maxent (Maximum Entropy Model):**
   Maxent is a widely used model for SDMs. It aims to find the distribution that is the most spread out (has the highest entropy) while satisfying the constraints of observed species presences and environmental variables. It's particularly useful when dealing with presence-only data. [More on Maxent](https://support.bccvl.org.au/support/solutions/articles/6000083216-maxent)

2. **GLM (Generalized Linear Model):**
   GLMs are a broad class of models that include linear regression as a special case. In the context of SDMs, GLMs can be extended to model species presence or absence based on environmental predictors.

3. **Random Forest:**
   Random Forest is an ensemble learning technique that builds multiple decision trees and combines their predictions. It's robust and can handle complex interactions between variables, making it suitable for SDMs.

4. **Boosted Regression Trees (BRT):**
   BRT is another ensemble method that combines multiple decision trees, but unlike Random Forest, it builds trees sequentially, with each tree trying to correct the errors of the previous one.

5. **SVM (Support Vector Machine):**
   SVMs are used for classification tasks and can be adapted to predict species presence or absence based on environmental variables.

6. **ANN (Artificial Neural Networks):**
   Neural networks can capture complex relationships in the data and have been used for SDMs, particularly for large datasets.

7. **GAM (Generalized Additive Model):**
   GAMs extend GLMs by allowing non-linear relationships between predictors and the response variable. They're useful for capturing complex species-environment relationships.

8. **Maxlike (Maximum Likelihood Model):**
   Maxlike models use maximum likelihood estimation to predict species distribution based on observed data and environmental predictors.

9. **MARS (Multivariate Adaptive Regression Splines):**
   MARS models can capture non-linear relationships and interactions between predictors. They're particularly useful when the relationships are complex and not well represented by linear models.

10. **SDMs with Hierarchical Models:**
    Some researchers use hierarchical models, such as Bayesian models, to incorporate prior knowledge and uncertainty in SDMs.

The choice of model depends on the nature of your data, the assumptions you're willing to make, the complexity of relationships, and the specific goals of your analysis. It's often recommended to compare multiple models and evaluate their performance using appropriate metrics before deciding on the best model for your SDM.

## Maxent

The Maxent algorithm, short for "Maximum Entropy," is a machine learning technique used primarily for species distribution modeling. It's designed to model the probability distribution of a species across geographic space based on environmental variables. Maxent aims to find the distribution that is the most spread out or has the highest entropy while satisfying a set of constraints provided by the available data.

Here's a high-level overview of how the Maxent algorithm works:

1. **Input Data:**
   Maxent requires two main types of input data: presence data (locations where the species is known to occur) and environmental variables (such as temperature, precipitation, land cover, etc.). The presence data provides information about where the species has been observed.

2. **Feature Creation:**
   Maxent uses the presence data to create a set of features (combinations of environmental variables) that represent the observed conditions at the presence locations.

3. **Model Training:**
   The goal of Maxent is to find a probability distribution of environmental conditions that matches the observed presence locations while maximizing entropy (spreading out the distribution as much as possible). It's formulated as a constrained optimization problem, where the model seeks to find the distribution that is closest to uniform (highest entropy) while satisfying constraints based on the presence data.

4. **Regularization:**
   Maxent uses regularization to avoid overfitting the model to the presence data. Regularization adds a penalty for overly complex models. This helps prevent the model from fitting the noise in the presence data.

5. **Probability Prediction:**
   Once the Maxent model is trained, it can be used to predict the probability of species presence across the entire study area based on the input environmental variables.

6. **Model Evaluation:**
   The model's predictive performance can be evaluated using various metrics, such as Area Under the Receiver Operating Characteristic Curve (AUC-ROC) or Area Under the Precision-Recall Curve (AUC-PR), which assess how well the model discriminates between presence and absence locations.

Maxent is popular for species distribution modeling because it's able to handle presence-only data (locations where the species is known to occur) and work with complex relationships between species and environmental variables. However, it's important to note that Maxent models can still be subject to bias and limitations based on data quality and the assumptions of the algorithm.

