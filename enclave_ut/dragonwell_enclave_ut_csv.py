#!/usr/bin/env python3

# coding=UTF-8

import csv
import pandas as pd

def create_csv(path, csv_head):
    with open(path, 'w') as f:
        csv_write = csv.writer(f)
        csv_write.writerow(csv_head)

def write_csv(path, data_row):
    with open(path, 'a+', encoding='utf-8') as f:
        csv_write = csv.writer(f)
        csv_write.writerow(data_row)

def read_csv(path):
    with open(path, "r", encoding='utf-8') as f:
        csv_read = csv.reader(f)
        for row in csv_read:
            print(row)

def update_total_statistic_data(path, row, index):
    df = pd.read_csv(path)
    df.loc[index] = row
    df.to_csv(path, index=None)

# step one: replace r'\n' to <br/>, replace r'\t' to '&nbsp'
# step two: convert csv to html
def convert_csv_to_html(path, column_name):
    df = pd.read_csv(path)
    df[column_name].replace({'\n': '<br/>', '\t': '&nbsp'}, regex=True, inplace=True)
    html_file = path.replace('.csv', '.html', 1)
    df.to_html(html_file, justify='center', escape=False)
