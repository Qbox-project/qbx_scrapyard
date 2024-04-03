return {
    useTarget = GetConvar('UseTarget', 'false') == 'true',
    debugPoly = false,
    useBlips = true,
    locations = {
        main = {
            coords = vec4(2403.51, 3127.95, 48.15, 250),
            blipName = 'Scrap Yard',
            blipIcon = 380,
            pedModel = 'a_m_m_hillbilly_01'
        },
        deliver = {
            coords = vec3(2351.5, 3132.96, 48.2),
            blipName = 'Scrap Yard Delivery',
            blipIcon = 810,
        }
    }
}
