# coding=utf-8
"""
Plot predictions made by the LSTM model

Author: Simon Hofmann | <[surname].[lastname][at]protonmail.com> | 2017
"""

import os.path
import matplotlib.pyplot as plt
from Meta_Functions import *


@true_false_request
def debug_plot():
    print("Do you want to plot results from the debugging-mode?")


debug = "/debug/" if debug_plot() else "/"


# Save plot
@true_false_request
def save_request():
    print("Do you want to save the plots")


plots = save_request()


subjects = [36]
wdic = "./LSTM"
wdic_plot = "../../Results/Plots/LSTM/"
wdic_lists = wdic + "/logs" + debug
lw = 0.5  # linewidth

for subject in subjects:
    wdic_sub = wdic + debug + "S{}/".format(str(subject).zfill(2))
    wdic_lists_sub = wdic_lists + "S{}/".format(str(subject).zfill(2))

    # Find correct files (csv-tables)
    for file in os.listdir(wdic_sub):
        if ".csv" in file:
            if "val_" in file:
                val_filename = file
            else:
                file_name = file

        elif ".txt" in file:
            acc_filename = file

    # Load data
    pred_matrix = np.loadtxt(wdic_sub + file_name, delimiter=",")
    val_pred_matrix = np.loadtxt(wdic_sub + val_filename, delimiter=",")

    # Import accuracies
    acc_date = np.loadtxt(wdic_sub + acc_filename, dtype=str, delimiter=";")  # Check (before ",")
    for info in acc_date:

        if "S-Fold(Round):" in info:
            s_rounds = np.array(list(map(int, info.split(": [")[1][0:-1].split(" "))))

        elif "Validation-Acc:" in info:
            val_acc = info.split(": ")[1].split(", ")  # Check (before "  ")
            v = []
            for i, item in enumerate(val_acc):
                if i == 0:  # first
                    v.append(float(item[1:]))
                elif i == (len(val_acc)-1):  # last one
                    v.append(float(item[0:-1]))
                else:
                    v.append(float(item))
            val_acc = v
            del v

        elif "mean(Accuracy):" in info:
            mean_acc = np.round(a=float(info.split(": ")[1]), decimals=3)

        elif "Hilbert_z-Power:" in info:
            hilb = info.split(": ")[1]
            hilb = True if "True" in hilb else False

        elif "repetition_set:" in info:
            reps = int(info.split(": ")[1])

        elif "batch_random:" in info:
            rnd_batch = info.split(": ")[1]
            rnd_batch = True if rnd_batch in "True" else False

        elif "batch_size:" in info:
            batch_size = int(info.split(": ")[1])

    # Number of Folds
    s_fold = int(len(pred_matrix[:, 0])/2)

    # Subplot division
    def subplot_div(n_s_fold):
        if n_s_fold < 10:
            sub_rows_f, sub_col_f, sub_n_f = n_s_fold, 1, 0
        else:
            sub_rows_f, sub_col_f, sub_n_f = int(n_s_fold / 2), 2, 0

        return sub_rows_f, sub_col_f, sub_n_f

    # # Plot predictions
    # open frame
    figsize = (12, s_fold * (3 if s_fold < 4 else 1))
    fig = plt.figure("{}-Folds | S{} | mean(val_acc)={} | 1Hz".format(s_fold, str(subject).zfill(2), mean_acc),
                     figsize=figsize)

    # Prepare subplot division
    sub_rows, sub_col, sub_n = subplot_div(n_s_fold=s_fold)

    # For each fold create plot
    for fold in range(s_fold):

        # Vars to plot
        pred = pred_matrix[fold*2, :]
        rating = pred_matrix[fold*2 + 1, :]
        val_pred = val_pred_matrix[fold*2, :]
        val_rating = val_pred_matrix[fold*2 + 1, :]

        # add subplot
        sub_n += 1
        fig.add_subplot(sub_rows, sub_col, sub_n)

        # plot
        # plt.plot(pred, label="prediction", marker='o', markersize=3)  # , style='r-'
        # plt.plot(rating, ls="dotted", label="rating", marker='o', mfc='none', markersize=3)
        # plt.plot(val_pred, label="val_prediction", marker='o', markersize=3)
        # plt.plot(val_rating, ls="dotted", label="val_rating", marker='o', mfc='none', markersize=3)
        plt.plot(pred, label="prediction", linewidth=lw)  # , style='r-'
        plt.plot(rating, ls="dotted", label="rating")
        plt.plot(val_pred, label="val_prediction", linewidth=lw)
        plt.plot(val_rating, ls="dotted", label="val_rating")
        plt.title(s="{}-Fold | val_acc={}".format(fold+1,
                                                  np.round(val_acc[int(np.where(np.array(s_rounds) == fold)[0])], 3)))

        # adjust size, add legend
        plt.xlim(0, len(pred))
        plt.ylim(-1.2, 2)
        plt.legend(bbox_to_anchor=(0., 0.90, 1., .102), loc=1, ncol=4, mode="expand", borderaxespad=0.)
        plt.tight_layout(pad=2)

    fig.show()

    if plots:
        plot_filename = "20{}{}{}*{}({})_{}-Folds_|_S{}_|_1Hz".format(file_name[0:9], "Hilbert_" if hilb else "", reps,
                                                                      "rnd-batch" if rnd_batch else "", batch_size,
                                                                      s_fold, subject)
        fig.savefig(wdic_plot + plot_filename)

    # # Plot accuracy-trajectories

    fig2 = plt.figure("{}-Folds Accuracies | S{} | mean(val_acc)={} | 1Hz ".format(s_fold,
                                                                                   str(subject).zfill(2),
                                                                                   mean_acc), figsize=figsize)

    # Prepare subplot division
    sub_rows, sub_col, sub_n = subplot_div(n_s_fold=s_fold)

    for fold in range(s_fold):

        # Load Data
        val_acc_fold = np.loadtxt(wdic_lists_sub + "{}/val_acc_list.txt".format(fold), delimiter=",")
        train_acc_fold = np.loadtxt(wdic_lists_sub + "{}/train_acc_list.txt".format(fold), delimiter=",")

        # add subplot
        sub_n += 1
        fig2.add_subplot(sub_rows, sub_col, sub_n)

        # plot
        plt.plot(train_acc_fold, label="train_acc", linewidth=lw/2)
        plt.plot(val_acc_fold, label="val_acc", linewidth=lw)

        plt.title(s="{}-Fold | val_acc={}".format(fold + 1,
                                                  np.round(val_acc[int(np.where(np.array(s_rounds) == fold)[0])], 3)))

        # adjust size, add legend
        plt.xlim(0, len(train_acc_fold))
        plt.ylim(0.0, 1.5)
        plt.legend(bbox_to_anchor=(0., 0.90, 1., .102), loc=1, ncol=4, mode="expand", borderaxespad=0.)
        plt.tight_layout(pad=2)

    fig2.show()

    # Plot
    if plots:
        plot_filename = "20{}{}{}*{}({})_{}-Folds_Accuracies_|_S{}_|_1Hz".format(file_name[0:9],
                                                                                 "Hilbert_" if hilb else "", reps,
                                                                                 "rnd-batch" if rnd_batch else "",
                                                                                 batch_size, s_fold, subject)
        fig2.savefig(wdic_plot + plot_filename)

    # # Plot loss-trajectories

    fig3 = plt.figure("{}-Folds Loss | S{} | mean(val_acc)={} | 1Hz ".format(s_fold, str(subject).zfill(2), mean_acc),
                      figsize=figsize)

    # Prepare subplot division
    sub_rows, sub_col, sub_n = subplot_div(n_s_fold=s_fold)

    for fold in range(s_fold):
        # Load Data
        val_loss_fold = np.loadtxt(wdic_lists_sub + "{}/val_loss_list.txt".format(fold), delimiter=",")
        train_loss_fold = np.loadtxt(wdic_lists_sub + "{}/train_loss_list.txt".format(fold), delimiter=",")

        # add subplot
        sub_n += 1
        fig3.add_subplot(sub_rows, sub_col, sub_n)

        # plot
        plt.plot(train_loss_fold, label="train_loss", linewidth=lw/2)
        plt.plot(val_loss_fold, label="val_loss", linewidth=lw)

        plt.title(s="{}-Fold | val_loss={}".format(fold + 1,
                                                   np.round(val_acc[int(np.where(np.array(s_rounds) == fold)[0])], 3)))

        # adjust size, add legend
        plt.xlim(0, len(train_loss_fold))
        plt.ylim(-0.05, 1.8)
        plt.legend(bbox_to_anchor=(0., 0.90, 1., .102), loc=1, ncol=4, mode="expand", borderaxespad=0.)
        plt.tight_layout(pad=2)

    fig3.show()

    # Plot
    if plots:
        plot_filename = "20{}{}{}*{}({})_{}-Folds_Loss_|_S{}_|_1Hz".format(file_name[0:9],
                                                                           "Hilbert_" if hilb else "", reps,
                                                                           "rnd-batch" if rnd_batch else "", batch_size,
                                                                           s_fold, subject)
        fig3.savefig(wdic_plot + plot_filename)


@true_false_request
def close_plots():
    print("Do you want to close plots?")


if close_plots():
    for _ in range(3):
        plt.close()
