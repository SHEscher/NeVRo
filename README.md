<h1>NeVRo – Neuro Virtual Reality </h1>

![NeVRo](./.NeVRoCover.png)

<h2>Decoding subjective emotional arousal from EEG during an immersive Virtual Reality experience</h2>
Code base of: <a href="https://doi.org/10.1101/2020.10.24.353722"> Hofmann, Klotzsche, Mariola, Nikulin, Villringer, & Gaebler. <i>bioRxiv</i>, 2020</a><br><br>

[![Python.pm](https://img.shields.io/badge/python->3.5-brightgreen.svg?maxAge=259200)](#)
[![Matlab.pm](https://img.shields.io/badge/matlab->R2016.a-red.svg?maxAge=259200)](#)
[![R.pm](https://img.shields.io/badge/R->3.4-informational.svg?maxAge=259200)](#)
[![version](https://img.shields.io/badge/version-2.1-yellow.svg?maxAge=259200)](#)

<h2>Introduction</h2>

We used virtual reality (VR) to investigate emotional arousal under naturalistic conditions. 45 subjects experienced virtual roller coaster rides while their neural (EEG) and peripheral physiological (ECG, GSR) responses were recorded. Afterwards, they rated their subject levels of arousal retrospectively on a continuous scale while viewing a recording of their experience.

<h2>Methods</h2>
We tackled the data with three model approaches. The corresponding code can be found in the respective folders.

<h3>SPoC Model</h3>
<a href="https://doi-org.browser.cbs.mpg.de/10.1016/j.neuroimage.2013.07.079">Source Power Comodulation (SPoC)</a> decomposes the EEG signal such that it maximizes the covariance between the power-band of the frequency of interest (here alpha, 8-12Hz) and the target variable (ratings).

<h3>CSP Model</h3>
<a href="https://ieeexplore.ieee.org/document/4408441/">Common Spatial Pattern (CSP)</a> algorithm derives a set of spatial filters to project the EEG data onto compontents whose band-power maximally relates to the prevalence of specified classes (here low and high arousal).<br>
<br>
This part of the study was published at IEEE VR 2018 in Reutlingen, Germany:<br>
<a href="https://ieeexplore.ieee.org/abstract/document/8446275"> Klotzsche, Mariola, Hofmann, Nikulin, Villringer, & Gaebler. <i>IEEE VR</i>, 2018.</a>  
<sup><sub>[<a href="https://github.com/eioe/NeVRo/tree/klotzsche2018_ieeevr">archived code</a>]</sub></sup>

<h3>LSTM Model</h3>
<a href="https://doi.org/10.1162/neco.1997.9.8.1735">Long Short-Term Memory (LSTM)</a> recurrent neural networks (RNNs) were trained on alpha-frequency components of the recorded EEG signal to predict subjective reports of arousal (ratings) in a binary (low and high arousal) and a continuous prediction task. The fed EEG components were generated via <a href="https://doi.org/10.1016/j.neuroimage.2011.01.057">Spatio Spectral Decomposition (SSD)</a> or SPoC. The SSD emphasizes the frequency of interest (here alpha) while attenuating the adjacent frequency bins. Performances of SPoC-trained models served as benchmark-proxies for models that were trained only on neural alpha information.<br>
Furthermore, we tested whether peripheral physiological responses, here the cardiac information (ECG), increases the performance of the model, and therefore encodes additional information about the subjective experience of arousal.<br>
<br>
This part of the study was published at IEEE AIVR 2018 in Taichung, Taiwan:<br>
<a href="https://ieeexplore.ieee.org/document/8613645"> Hofmann, Klotzsche, Mariola, Nikulin, Villringer, & Gaebler. <i>IEEE AIVR</i>, 2018</a>


<h3>Versions</h3>

###### version 2.1+

`2021`: additional linear model, new cross-validation regime, and further sub-analyses. Encouraged by valuable feedback via this [peer-review](https://hyp.is/go?url=https%3A%2F%2Fwww.biorxiv.org%2Fcontent%2F10.1101%2F2020.10.24.353722v3&group=q5X6RWJ6). 

###### version 2.0

`2018-2020`: preprocessing for models (SPoC, CSP, LSTM) was harmonized, and their evaluation and metrics were adapted accordingly. Plus, a more detailed documentation is available. Code for extended & harmonized version of the study (see [bioRxiv preprint](https://www.biorxiv.org/content/10.1101/2020.10.24.353722v3)).

###### version 1.x
`2017-2018`: Code of two above mentioned IEEE conference publications.

<h3>Collaborators</h3>
<a href="https://github.com/SHEscher">Simon M. Hofmann</a><br>
<a href="https://github.com/eioe">Felix Klotzsche</a><br>
<a href="https://github.com/langestroop">Alberto Mariola</a>
