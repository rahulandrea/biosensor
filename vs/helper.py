import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns
import plotly.express as px
import plotly.graph_objs as go
from plotly.subplots import make_subplots

def convert_raw_to_csv(input_path, output_path, delimiter="\t", skiprows=0, header='infer'):
    """
    Konvertiert eine RAW-Datei in eine CSV-Datei.
    
    Parameter:
    - input_path: Pfad zur .raw/.txt Datei
    - output_path: Zielpfad zur .csv Datei
    - delimiter: Trennzeichen in der RAW-Datei (z. B. '\t', ';', ',', etc.)
    - skiprows: Anzahl der zu überspringenden Zeilen (z. B. Metadaten)
    - header: 'infer', None oder Zeilennummer des Headers
    """
    try:
        df = pd.read_csv(input_path, delimiter=delimiter, skiprows=skiprows, header=header)
        df.to_csv(output_path, index=False)
        print(f"Erfolgreich konvertiert: {output_path}")
    except Exception as e:
        print(f"Fehler beim Konvertieren: {e}")

def plot_aligned_to_end_injections(df, sensor_name):
    # Liste der vorhandenen Injektionsintervalle
    intervals = sorted(df['Inj.'].dropna().unique())

    # Plot erstellen
    fig = go.Figure()

    # Jeden Injektionsintervall einzeln plotten
    for inj_interval in intervals:
        df_inj = df[df['Inj.'] == inj_interval].copy()

        if df_inj.empty:
            continue

        x = df_inj['T  (s)'] - df_inj['T  (s)'].iloc[0]  # Zeit relativ zum Start des Intervalls
        y = df_inj[sensor_name] - df_inj[sensor_name].iloc[-1]  # Sensorwert auf Endwert normiert (Endwert → 0)

        fig.add_trace(go.Scatter(
            x=x,
            y=y,
            mode='lines',
            name=f'Inj {inj_interval}'
        ))

    # Layout
    fig.update_layout(
        title=f'Plot auf Endpunkt ausgerichtet: {sensor_name} pro Injektionsintervall',
        xaxis_title='Relative Zeit (s)',
        yaxis_title='Sensorwert (Δ zum Endpunkt)',
        legend_title='Injektionsintervall',
        template='plotly_white'
    )

    # Plot anzeigen
    fig.show()

def plot_all_sensors(df):
    # Achsen definieren
    x = df['T  (s)']
    sensor_spalten = df.columns[1:9]
    inj = df['Inj.']
    val = df['Val.']

    # Plot erstellen
    fig = go.Figure()

    # Sensoren plotten
    for sensor in sensor_spalten:
        fig.add_trace(go.Scatter(
            x=x,
            y=df[sensor],
            mode='lines',
            name=sensor
        ))

    # Injection Change
    change_times = []
    for i in range(1, len(df)):
        if inj.iloc[i] != inj.iloc[i-1]:
            change_times.append(x.iloc[i])

    # Y-Range bestimmen
    ymin = df[sensor_spalten].min().min()
    ymax = df[sensor_spalten].max().max()

    # Eine einzige Injection Change Trace
    vline_x = []
    vline_y = []

    for ct in change_times:
        vline_x.extend([ct, ct, None])
        vline_y.extend([ymin, ymax, None])

    fig.add_trace(go.Scatter(
        x=vline_x,
        y=vline_y,
        mode='lines',
        line=dict(color='red', width=2, dash='dash'),
        name='Injection Change'
    ))

    # Val. Kategorien definieren
    val_colors = {
        1: 'rgba(255, 0, 0, 0.1)',    # Rot für negativ
        2: 'rgba(0, 255, 0, 0.1)',    # Grün für positiv
        3: 'rgba(0, 0, 255, 0.1)'     # Blau für Harnstoff
    }

    val_labels = {
        1: 'Negativ Sample',
        2: 'Positiv Sample',
        3: 'Harnstoff'
    }

    # Val.-Bereiche markieren
    current_val = val.iloc[0]
    start_time = x.iloc[0]

    for i in range(1, len(df)):
        if val.iloc[i] != current_val:
            end_time = x.iloc[i]
            fig.add_vrect(
                x0=start_time, x1=end_time,
                fillcolor=val_colors[current_val],
                opacity=0.5,
                layer='below',
                line_width=0
            )
            current_val = val.iloc[i]
            start_time = x.iloc[i]

    # Letzter Bereich bis zum Ende
    fig.add_vrect(
        x0=start_time, x1=x.iloc[-1],
        fillcolor=val_colors[current_val],
        opacity=0.5,
        layer='below',
        line_width=0
    )

    # Dummy-Traces für Legende
    for val_code, color in val_colors.items():
        fig.add_trace(go.Scatter(
            x=[None],
            y=[None],
            mode='markers',
            marker=dict(size=10, color=color),
            name=val_labels[val_code]
        ))

    # Layout finalisieren
    fig.update_layout(
        title='Sensorwerte über Zeit',
        xaxis_title='Zeit (s)',
        yaxis_title='Nanometer',
        legend_title='Legende',
        template='plotly_white'
    )

    # Plot anzeigen
    fig.show()

def plot_injection(df, inj):
    # Nur den gewünschten Injektionsintervall auswählen
    df_inj = df[df['Inj.'] == inj].copy()
    
    if df_inj.empty:
        print(f"Keine Daten für Injektionsintervall {inj} gefunden.")
        return

    # Achsen definieren
    x = df_inj['T  (s)']
    sensor_spalten = df_inj.columns[1:9]
    val = df_inj['Val.']

    # Plot erstellen
    fig = go.Figure()

    # Sensoren plotten
    for sensor in sensor_spalten:
        fig.add_trace(go.Scatter(
            x=x,
            y=df_inj[sensor],
            mode='lines',
            name=sensor
        ))

    # Val. Kategorien definieren
    val_colors = {
        1: 'rgba(255, 0, 0, 0.1)',    # Rot für negativ
        2: 'rgba(0, 255, 0, 0.1)',    # Grün für positiv
        3: 'rgba(0, 0, 255, 0.1)'     # Blau für Harnstoff
    }

    val_labels = {
        1: 'Negativ Sample',
        2: 'Positiv Sample',
        3: 'Harnstoff'
    }

    # Val.-Bereiche markieren
    current_val = val.iloc[0]
    start_time = x.iloc[0]

    for i in range(1, len(df_inj)):
        if val.iloc[i] != current_val:
            end_time = x.iloc[i]
            fig.add_vrect(
                x0=start_time, x1=end_time,
                fillcolor=val_colors.get(current_val, 'rgba(0,0,0,0.1)'),
                opacity=0.5,
                layer='below',
                line_width=0
            )
            current_val = val.iloc[i]
            start_time = x.iloc[i]

    # Letzter Bereich bis zum Ende
    fig.add_vrect(
        x0=start_time, x1=x.iloc[-1],
        fillcolor=val_colors.get(current_val, 'rgba(0,0,0,0.1)'),
        opacity=0.5,
        layer='below',
        line_width=0
    )

    # Dummy-Traces für Legende
    for val_code, color in val_colors.items():
        fig.add_trace(go.Scatter(
            x=[None],
            y=[None],
            mode='markers',
            marker=dict(size=10, color=color),
            name=val_labels[val_code]
        ))

    # Layout finalisieren
    fig.update_layout(
        title=f'Sensorwerte - Injektionsintervall {inj}',
        xaxis_title='Zeit (s)',
        yaxis_title='Nanometer',
        legend_title='Legende',
        template='plotly_white'
    )

    # Plot anzeigen
    fig.show()

def plot_injection_aligned_to_end(df, inj):
    # Nur den gewünschten Injektionsintervall auswählen
    df_inj = df[df['Inj.'] == inj].copy()
    
    if df_inj.empty:
        print(f"Keine Daten für Injektionsintervall {inj} gefunden.")
        return

    # Achsen definieren
    x = df_inj['T  (s)'] - df_inj['T  (s)'].iloc[0]  # Zeit relativ zum Start
    sensor_spalten = df_inj.columns[1:9]
    val = df_inj['Val.']

    # Plot erstellen
    fig = go.Figure()

    # Sensoren plotten (auf Endpunkt ausgerichtet)
    for sensor in sensor_spalten:
        y_shifted = df_inj[sensor] - df_inj[sensor].iloc[-1]  # Endwert auf 0 setzen
        fig.add_trace(go.Scatter(
            x=x,
            y=y_shifted,
            mode='lines',
            name=sensor
        ))

    # Val. Kategorien definieren
    val_colors = {
        1: 'rgba(255, 0, 0, 0.1)',    # Rot für negativ
        2: 'rgba(0, 255, 0, 0.1)',    # Grün für positiv
        3: 'rgba(0, 0, 255, 0.1)'     # Blau für Harnstoff
    }

    val_labels = {
        1: 'Negativ Sample',
        2: 'Positiv Sample',
        3: 'Harnstoff'
    }

    # Val.-Bereiche markieren
    current_val = val.iloc[0]
    start_time = x.iloc[0]

    for i in range(1, len(df_inj)):
        if val.iloc[i] != current_val:
            end_time = x.iloc[i]
            fig.add_vrect(
                x0=start_time, x1=end_time,
                fillcolor=val_colors.get(current_val, 'rgba(0,0,0,0.1)'),
                opacity=0.5,
                layer='below',
                line_width=0
            )
            current_val = val.iloc[i]
            start_time = x.iloc[i]

    # Letzter Bereich bis zum Ende
    fig.add_vrect(
        x0=start_time, x1=x.iloc[-1],
        fillcolor=val_colors.get(current_val, 'rgba(0,0,0,0.1)'),
        opacity=0.5,
        layer='below',
        line_width=0
    )

    # Dummy-Traces für Legende
    for val_code, color in val_colors.items():
        fig.add_trace(go.Scatter(
            x=[None],
            y=[None],
            mode='markers',
            marker=dict(size=10, color=color),
            name=val_labels[val_code]
        ))

    # Layout finalisieren
    fig.update_layout(
        title=f'Sensorwerte (Endpunkt ausgerichtet) - Injektionsintervall {inj}',
        xaxis_title='Relative Zeit (s)',
        yaxis_title='Δ Sensorwert (zum Endpunkt)',
        legend_title='Legende',
        template='plotly_white'
    )

    # Plot anzeigen
    fig.show()

def plot_injection_normalized(df, inj):
    # Nur den gewünschten Injektionsintervall auswählen
    df_inj = df[df['Inj.'] == inj].copy()
    
    if df_inj.empty:
        print(f"Keine Daten für Injektionsintervall {inj} gefunden.")
        return

    # Achsen definieren
    x = df_inj['T  (s)'] - df_inj['T  (s)'].iloc[0]  # Zeit relativ zum Start
    sensor_spalten = df_inj.columns[1:9]
    val = df_inj['Val.']

    # Plot erstellen
    fig = go.Figure()

    # Sensoren plotten (normiert auf Startwert)
    for sensor in sensor_spalten:
        fig.add_trace(go.Scatter(
            x=x,
            y=df_inj[sensor] - df_inj[sensor].iloc[0],  # normiert
            mode='lines',
            name=sensor
        ))

    # Val. Kategorien definieren
    val_colors = {
        1: 'rgba(255, 0, 0, 0.1)',    # Rot für negativ
        2: 'rgba(0, 255, 0, 0.1)',    # Grün für positiv
        3: 'rgba(0, 0, 255, 0.1)'     # Blau für Harnstoff
    }

    val_labels = {
        1: 'Negativ Sample',
        2: 'Positiv Sample',
        3: 'Harnstoff'
    }

    # Val.-Bereiche markieren
    current_val = val.iloc[0]
    start_time = x.iloc[0]

    for i in range(1, len(df_inj)):
        if val.iloc[i] != current_val:
            end_time = x.iloc[i]
            fig.add_vrect(
                x0=start_time, x1=end_time,
                fillcolor=val_colors.get(current_val, 'rgba(0,0,0,0.1)'),
                opacity=0.5,
                layer='below',
                line_width=0
            )
            current_val = val.iloc[i]
            start_time = x.iloc[i]

    # Letzter Bereich bis zum Ende
    fig.add_vrect(
        x0=start_time, x1=x.iloc[-1],
        fillcolor=val_colors.get(current_val, 'rgba(0,0,0,0.1)'),
        opacity=0.5,
        layer='below',
        line_width=0
    )

    # Dummy-Traces für Legende
    for val_code, color in val_colors.items():
        fig.add_trace(go.Scatter(
            x=[None],
            y=[None],
            mode='markers',
            marker=dict(size=10, color=color),
            name=val_labels[val_code]
        ))

    # Layout finalisieren
    fig.update_layout(
        title=f'Normierte Sensorwerte - Injektionsintervall {inj}',
        xaxis_title='Relative Zeit (s)',
        yaxis_title='Δ Sensorwert (zum Start)',
        legend_title='Legende',
        template='plotly_white'
    )

    # Plot anzeigen
    fig.show()

def plot_normalized_injections(df, sensor_name):
    # Liste der vorhandenen Injektionsintervalle
    intervals = sorted(df['Inj.'].dropna().unique())

    # Plot erstellen
    fig = go.Figure()

    # Jeden Injektionsintervall einzeln plotten
    for inj_interval in intervals:
        df_inj = df[df['Inj.'] == inj_interval].copy()

        if df_inj.empty:
            continue

        x = df_inj['T  (s)'] - df_inj['T  (s)'].iloc[0]  # Zeit relativ zum Start des Intervalls
        y = df_inj[sensor_name] - df_inj[sensor_name].iloc[0]  # Sensorwert normiert auf 0 beim Start

        fig.add_trace(go.Scatter(
            x=x,
            y=y,
            mode='lines',
            name=f'Inj {inj_interval}'
        ))

    # Layout
    fig.update_layout(
        title=f'Normierter Plot: {sensor_name} pro Injektionsintervall',
        xaxis_title='Relative Zeit (s)',
        yaxis_title='Sensorwert (Δ zum Start)',
        legend_title='Injektionsintervall',
        template='plotly_white'
    )

    # Plot anzeigen
    fig.show()