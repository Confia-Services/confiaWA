-- 0011 · definitive launch categories and services (decided 26 oct 2026, Javi).
update categories set name = 'Depilación, estética, cejas y pestañas' where slug = 'depilacion';

insert into services (category_id, slug, name, reference_price, duration_min, requires_advance_booking)
select c.id, s.slug, s.name, s.price, s.dur, s.adv
from (values
  ('unas',       'manicure',          'Manicure',                      700,  60,  false),
  ('unas',       'pedicure',          'Pedicure',                      800,  60,  false),
  ('unas',       'manicure_pedicure', 'Manicure + pedicure',           1400, 110, false),
  ('unas',       'gel',               'Uñas en gel / acrílico',        1500, 90,  false),
  ('unas',       'retiro',            'Retiro de gel / acrílico',      400,  30,  false),
  ('peluqueria', 'brushing',          'Brushing',                      1100, 60,  false),
  ('peluqueria', 'corte',             'Corte',                         1000, 45,  false),
  ('peluqueria', 'lavado_brushing',   'Lavado + brushing',             1300, 75,  false),
  ('peluqueria', 'rizos',             'Rizos (definición / tratamiento)', 1500, 90, false),
  ('peluqueria', 'color',             'Color / tinte',                 null, 120, false),
  ('peluqueria', 'keratina',          'Keratina / alisado',            null, 150, true),
  ('peluqueria', 'peinado_evento',    'Peinado de evento',             1800, 75,  true),
  ('barberia',   'corte_barberia',    'Corte',                         600,  40,  false),
  ('barberia',   'corte_barba',       'Corte + barba',                 800,  50,  false),
  ('barberia',   'barba',             'Barba',                         400,  25,  false),
  ('maquillaje', 'maquillaje_social', 'Maquillaje social',             2000, 60,  false),
  ('maquillaje', 'maquillaje_novia',  'Maquillaje de novia (con prueba)', 5000, 120, true)
) as s(cat, slug, name, price, dur, adv)
join categories c on c.slug = s.cat
on conflict (slug) do update
  set name = excluded.name,
      reference_price = excluded.reference_price,
      duration_min = excluded.duration_min,
      requires_advance_booking = excluded.requires_advance_booking,
      active = true;