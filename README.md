# Neurio power monitor
## monitor neurio power meter from linux

This version is using BASH, I would like to rewrite this for python

I no longer use this bash script, and am polling the neurio monitor directly from home assistant using the REST API and hitting `http://neurio.ip/current-sample`.

Although I am using home assistant at the moment, and that is much preferable than having some third party remote server controlling my data, I don't like the extra workload of to-the-second sensor polling and data mangling within HA itself. So I am likely to create a standalone "something" to take that workload and then have HA grab (or push to HA) relevant power entries as required. *TBH, I'm not sure how I'm going to incorporate this yet, still a work in progress, however, this bash script will and does work in a pinch*

## Neurio hardware:
this script was initially developed on the release firmware. For a long time I had the neurio device disconnected from the internet, and then for a while it was connected and allowed to connect back to their server, however I have just stopped it once more since I do not want the developers to further update the firmware in it in the event they remove some feature or endpoint that I have come to rely on. 

````
Hardware Version: 012.00013A.E
Firmware Version: 1.7.0
````

## Requires:
`jq` package: `sudo apt install jq`

>Package: jq  
Version: 1.6-1ubuntu0.20.04.1  
Priority: optional  
Section: universe/utils  
Origin: Ubuntu  
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>  
Original-Maintainer: ChangZhuo Chen (陳昌倬) <czchen@debian.org>  
Bugs: https://bugs.launchpad.net/ubuntu/+filebug  
Installed-Size: 99.3 kB  
Depends: libjq1 (= 1.6-1ubuntu0.20.04.1), libc6 (>= 2.4)  
Homepage: https://github.com/stedolan/jq  
Download-Size: 50.2 kB  
APT-Manual-Installed: yes  
APT-Sources: http://archive.ubuntu.com/ubuntu focal-updates/universe amd64 Packages  
Description: lightweight and flexible command-line JSON processor  
 jq is like sed for JSON data – you can use it to slice  
 and filter and map and transform structured data with  
 the same ease that sed, awk, grep and friends let you  
 play with text.  
 .  
 It is written in portable C, and it has minimal runtime  
 dependencies.  
 .  
 jq can mangle the data format that you have into the  
 one that you want with very little effort, and the  
 program to do so is often shorter and simpler than  
 you’d expect.  

## Home Assistant integration
The BASH script here is not used with HA directly, in fact not at all.

I include the next section more for my own records, but this is how I have integrated Neurio into HA. 

This definitely needs cleaning/refining. There's a bit of duplication due to setting it up and then changing it and I haven't decided how I want to finish it ATM, so it is what it is. Everything is hardcoded, I haven't yet scripted the "loading" of channels as per the dynamic entries they could be, but that is mostly because (in general) once you set it up, you are very rarely going to change it! 

I only have two CT's attached to my device and three channels.
````
CT1 = main CT on the single phase into my meter box
CT2 = secondary CT on one circuit of the house (in my case, it's the Airconditioner circuit)

CH1 = CT1         total consumption
CH2 = CT1 - CT2   Main circuit
CH3 = CT2         Airconditioner circuit
````

All entered into the `configuration.yaml` file:

````
  - platform: rest
    name: neurio
    resource: http://192.168.999.999/current-sample
    json_attributes:
     - timestamp
     - channels
     - cts
    value_template: "{{ value_json['channels'][0]['v_V'] }}" # 'OK' # {{ value_json.channels[0].v_V }}
    scan_interval: 1
  - platform: template
    sensors:
      # channels are arbitrary, they are created in the sensor itself
      # and can reflect a calculation of CT values
      channel1_watts:  # CH1 is on the main input and is all inclusive
        friendly_name: 'Watts (Total)'
        value_template: "{{ states.sensor.neurio.attributes['channels'][0]['p_W'] }}" 
        unit_of_measurement: 'W'
      channel2_watts:  # CH2 is a calculation of CT1 - CT2
        friendly_name: 'Watts (Main)'
        value_template: "{{ states.sensor.neurio.attributes['channels'][1]['p_W'] }}" 
        unit_of_measurement: 'W'
      channel3_watts:  # this is just CT2
        friendly_name: 'Watts (Air)'
        value_template: "{{ states.sensor.neurio.attributes['channels'][2]['p_W'] }}" 
        unit_of_measurement: 'W'
      channel1_impws:
        friendly_name: 'Imported Energy Total (Ws)'
        value_template: "{{ states.sensor.neurio.attributes['channels'][0]['eImp_Ws'] }}" 
        unit_of_measurement: 'Ws'
      channel1_expws:
        friendly_name: 'Exported Energy Total (Ws)'
        value_template: "{{ states.sensor.neurio.attributes['channels'][0]['eExp_Ws'] }}" 
        unit_of_measurement: 'Ws'
      channel1_realw:
        friendly_name: 'Reactive Power (Main Phase)'
        value_template: "{{ states.sensor.neurio.attributes['channels'][0]['q_VAR'] }}" 
        unit_of_measurement: 'VA'
      channel1_type: # Types can be: PHASE_A_CONSUMPTION, PHASE_B_CONSUMPTION, PHASE_C_CONSUMPTION, NET, GENERATION, CONSUMPTION, SUBMETER.
        friendly_name: 'Type'
        value_template: "{{ states.sensor.neurio.attributes['channels'][0]['type'] }}" 

      voltage_a:
        friendly_name: 'AC Volts'
        #value_template: "{{state_attr('sensor.neurio','channels')['0']['v_V']}}"
        value_template: "{{ states.sensor.neurio.attributes['channels'][0]['v_V']|round(1) }}"  # '{{ value_json.channels }}'
        unit_of_measurement: 'V'
      voltage_b:
        friendly_name: 'AC Volts'
        value_template: "{{ states.sensor.neurio.attributes['channels'][1]['v_V'] }}" 
        unit_of_measurement: 'V'
      voltage_c:
        friendly_name: 'AC Volts'
        value_template: "{{ states.sensor.neurio.attributes['channels'][2]['v_V'] }}" 
        unit_of_measurement: 'V'
      ct1_amps:
        friendly_name: 'ct1 amps'
        value_template: "{{ states.sensor.neurio.attributes['cts'][0]['i_A'] }}" 
        unit_of_measurement: 'A'
      ct2_amps:
        friendly_name: 'ct2 amps'
        value_template: "{{ states.sensor.neurio.attributes['cts'][1]['i_A'] }}" 
        unit_of_measurement: 'A'
      ct1_watts:
        friendly_name: 'ct1 watts'
        value_template: "{{ states.sensor.neurio.attributes['cts'][0]['p_W'] }}" 
        unit_of_measurement: 'W'
      ct2_watts:
        friendly_name: 'ct2 watts'
        value_template: "{{ states.sensor.neurio.attributes['cts'][1]['p_W'] }}" 
        unit_of_measurement: 'W'
      ct1_qvar:
        friendly_name: 'ct1 Reactive Power'
        value_template: "{{ states.sensor.neurio.attributes['cts'][0]['q_Var'] }}" 
        unit_of_measurement: 'VA'
      ct2_qvar:
        friendly_name: 'ct2 Reactive Power'
        value_template: "{{ states.sensor.neurio.attributes['cts'][1]['q_Var'] }}" 
        unit_of_measurement: 'VA'
````
