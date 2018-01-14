installs tinc:
  pkg.installed:
    - name: tinc

{% set base_path = "/etc/tinc" %}
{% set name = pillar['tinc'][grains['id']]['name'] %}

{{base_path}}/nets.boot:
  file.managed:
    - source: "salt://tinc/nets.boot"
    - user: root
    - group: root
    - mode: 644

{{base_path}}/holonet:
  file.directory:
    - user: root
    - group: root
    - mode: 755

{{base_path}}/holonet/tinc-up:
  file.managed:
    - source: "salt://tinc/holonet/tinc-up"
    - user: root
    - group: root
    - mode: 744
    - template: jinja
    - context:
      ip: {{ pillar['tinc'][grains['id']]['local_address'] }}

{{base_path}}/holonet/tinc-down:
  file.managed:
    - source: "salt://tinc/holonet/tinc-down"
    - user: root
    - group: root
    - mode: 744
    - template: jinja
    - context:
      ip: {{ pillar['tinc'][grains['id']]['local_address'] }}

{{base_path}}/holonet/tinc.conf:
  file.managed:
    - source: "salt://tinc/holonet/tinc.conf"
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
      id: {{ name }}
      connect_to: {{ pillar['tinc'][grains['id']]['connect_to'] }}

{{base_path}}/holonet/hosts:
  file.directory:
    - user: root
    - user: root
    - mode: 755

{{base_path}}/holonet/rsa_key.priv:
  file.managed:
    - source: 'salt://tinc/keys/private/{{name}}'
    - user: root
    - group: root
    - mode: 600

{% for host, host_config in pillar['tinc'].items() %}
{% set hostname = host_config['name'] %}
{{base_path}}/holonet/hosts/{{ hostname }}:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents:
      - "Address = {{ salt.mine.get(host, 'network.interface')[host][0]['address'] }}"
      - Port = 655
      - Subnet = {{ host_config['route'] }}

Append public key to {{ hostname }}:
  file.append:
    - name: {{base_path}}/holonet/hosts/{{ hostname }}
    - source: salt://tinc/keys/public/{{ hostname }}
{% endfor %}

restart_tincd:
  module.run:
    - name: service.restart
    - m_name: tinc
