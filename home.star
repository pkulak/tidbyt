load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("math.star", "math")

def main(config):
    key = config.get('ha_key')

    return render.Root(
        delay = 5000,
        max_age = 120,
        child = render.Row(
            expanded=True,
            main_align="space_around",
            children=[
                render.Column(
                    expanded=True,
                    main_align="space_around",
                    children=[
                        render.Row(
                            children=[
                                render.Text("70: ", color="#84DCC6"),
                                render.Text(get_bus(key, 70), color=get_bus_color(key, 70))
                            ]
                        ),
                        render.Row(
                            children=[
                                render.Text("17: ", color="#84DCC6"),
                                render.Text(get_bus(key, 17), color=get_bus_color(key, 17))
                            ]
                        ),
                        render.Row(
                            children=[
                                render.Text("72: ", color="#84DCC6"),
                                render.Text(get_bus(key, 72), color=get_bus_color(key, 72))
                            ]
                        ),
                    ]
                ),
                render.Column(
                    expanded=True,
                    main_align="space_around",
                    children=[
                        get_clock(),
                        render.Text(str(get_temp(key)) + "°", color="#8b95c9"),
                        get_last_row(key),
                    ]
                )
            ]
        )
    )

def get_state(key, entity):
    url = "http://ha.home/api/states/" + entity
    headers = {'Authorization': 'Bearer ' + key}
    return http.get(url, headers=headers).json()

def get_bus(key, route):
    res = get_state(key, "timer.bus_" + str(route))

    if 'finishes_at' in res['attributes']:
        eta = time.parse_time(res['attributes']['finishes_at'])
        duration = eta - time.now()
        wait = int(math.round(duration.minutes))

        if wait > 90:
            return "∞"
        else:
            return str(wait) + "m"
    else:
        return "0m"

def get_bus_color(key, route):
    res = get_state(key, "input_boolean.bus_" + str(route) + "_maybe")

    if res['state'] == 'off':
        return "#D6EDFF"
    else:
        return "#444"

def get_temp(key):
    res = get_state(key, "sensor.temperature")
    temp = float(res['state'])
    return math.round(temp * 10) / 10

def get_rain(key):
    res = get_state(key, "sensor.precipitation_per_hour")
    rain = float(res['state'])

    if rain < 1 and rain > 0:
        rain = 1

    return int(math.round(rain))

def get_co2(key):
    res = get_state(key, "sensor.awair_bunny_co2")
    return int(math.round(float(res['state']) / 100))

def get_humidity(key):
    res = get_state(key, "sensor.awair_bunny_humid")
    return int(math.round(float(res['state'])))

def get_kw(key):
    res = get_state(key, "sensor.cph50_power_output")
    
    if res['state'] == 'unavailable':
        return 0

    return float(res['state'])

def get_clock():
    now = time.now()
    return render.Text(now.format("3:04"), color="#ACD7EC")

def get_last_row(key):
    rain = get_rain(key)
    kw = get_kw(key)
    co2 = get_co2(key)
    humidity = get_humidity(key)
    child = None

    if kw > 0:
        child = render.Text(str(kw) + "kW", color="#478978")
    elif rain > 0:
        child = render.Text(str(rain) + "mm", color="#478978")
    else:
        child = render.Animation(
            children = [
                render.WrappedText(str(co2) + "co2", width=23, color="#478978"),
                render.WrappedText(str(humidity) + "%", width=23, color="#478978"),
            ]
        )

    return child

