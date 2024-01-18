load("render.star", "render")
load("http.star", "http")
load("time.star", "time")
load("math.star", "math")

def main(config):
    key = config.get('ha_key')

    return render.Root(
        delay = 8000,
        max_age = 120,
        child = render.Row(
            expanded=True,
            main_align="space_around",
            children=[
                render.Column(
                    expanded=True,
                    main_align="space_around",
                    children=[
                        get_bus_row(key, 70),
                        get_bus_row(key, 17),
                    ]
                ),
                render.Column(
                    expanded=True,
                    main_align="space_around",
                    children=[
                        get_clock(),
                        render.Text(str(get_temp(key)) + "°", color="#ACD7EC"),
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

def get_calendar(key):
    start_time = ''
    event = ''

    for cal in ['household', 'gwen', 'phil', 'phil_s_work', 'charlie']:
        res = get_state(key, "calendar." + cal)
        attrs = res['attributes']

        if 'start_time' not in attrs:
            continue

        if res['state'] == 'on':
            return "Now: " + attrs['message']

        if start_time == '' or attrs['start_time'] < start_time:
            start_time = attrs['start_time']
            event = attrs['message']

    if start_time == '':
        return ''

    ampm = 'AM'
    hour = int(start_time.split(' ')[1].split(':')[0])
    minute = int(start_time.split(' ')[1].split(':')[1])

    if hour == 12:
        ampm = 'PM'
    if hour > 12:
        ampm = 'PM'
        hour = hour - 12
    
    if minute == 0:
        return '{}{} {}'.format(hour, ampm, event)
    else:
        return '{}:{} {}'.format(hour, minute, event)

def get_bus_row(key, route):
    return render.Row(
        cross_align="center",
        children=[
            render.Circle(
                color="#8B95C9",
                diameter=13,
                child=render.Text(str(route), color="#000", font="tom-thumb"),
            ),
            render.Text(" " + get_bus(key, route), color=get_bus_color(key, route))
        ]
    )

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
        return "#555"

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
    child = None

    if kw > 0:
        child = render.Text(str(kw) + "kW", color="#478978")
    elif rain > 0:
        child = render.Text(str(rain) + "mm", color="#478978")
    else:
        cal = get_calendar(key)

        if cal == '':
            return render.Text("None", color="#555")

        time = cal.split(' ', 1)[0]
        event = cal.split(' ', 1)[1]

        child = render.Animation(
            children=[
                render.WrappedText(time + ' ', width=24, color="#84DCC6"),
                render.WrappedText(event, width=24, height=8, color="#478978")
            ]
        )

    return child

