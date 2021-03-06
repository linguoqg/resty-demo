define ['regularjs','semantic-ui', 'rgl!/html/module/setting/setting.html', '/js/http.js','/js/plugin/app/datepicker.js','/js/plugin/app/dateformat.js'], (Regular,Semantic, tpl, $http)->
  Regular.extend(
    template: tpl
    data:
      product_items:['编号','名称','编码','成本','时间']
      user_items:['编号','登录名','姓名','电话','权限','时间']
      updateP:[]
      pName:[]
      pBarCode:[]
      pCost:[]
      pDate:[]
      cerror:[]
      derror:[]
      s_tab:
        first: true, second: false, third: false
      config:
        format: "yyyymmdd", minViewMode: 0, language: "zh-CN", autoclose: true,todayHighlight:true,clearBtn:true
      sState:
        twice: true, icon: 'play', loading: false, error: true
      rep:
        success: false, error: false
      modalConfig:
        selector    :
          close    : '.close,.cancel',
#          deny     : '.cancel',
          approve  : '.ok'
    active: (tab)->
      component = this
      switch tab
        when 'first' then component.data.s_tab = first: true, second: false, third: false
        when 'second' then component.data.s_tab = first: false, second: true, third: false
        when 'third' then component.data.s_tab = first: false, second: false, third: true

    init:->
      component = this
      component.product()
      component.user()

    product:->
      component = this
      $http.get('/api/v1.0/settings/products', (rep)->
        if rep
          component.data.products=rep
          component.$update()
      )

    user:->
      component = this
      $http.get('/api/v1.0/users', (rep)->
        if rep
          component.data.users=rep
          component.$update()
      )

    beforeUpdateUser:(id)->
      component = this
      component.data.roles={}
      $http.get('/api/v1.0/users/'+id,(rep)->
        if rep
          component.data.updateUser=rep
          ids=[]
          for p in component.data.updateUser.permissions
            ids.push(p.id)
          component.$update()
          component.getAllPermissions(ids)
          $('.modal.updateUser').modal(component.data.modalConfig).modal('show')
      )

    beforeDeleteUser:(id,name)->
      component = this
      component.data.updateUser = {id: id,name:name}
      $('.modal.deleteUser').modal(component.data.modalConfig).modal('show')

    deleteUser:(id)->
      component = this
      $http.delete('/api/v1.0/users/'+component.data.updateUser.id,(rep)->
        if rep
          component.user()
          component.$update()
          $('.modal.deleteUser').modal('hide')
      )

    beforeSaveUser:->
      component = this
      component.data.updateUser = {}
      component.getAllRoles()
      $('.modal.updateUser').modal(component.data.modalConfig).modal('show')


    getAllRoles:->
      component = this
      component.data.roles={}
      $http.get('/api/v1.0/roles',(rrep)->
        if rrep
          component.data.roles=rrep
          component.$update()
      )

    getAllPermissions:(ids)->
      component = this
      $http.get('/api/v1.0/permissions',(rrep)->
        if rrep
          component.data.permissions=rrep
          if ids
            for p in component.data.permissions
              if ids.indexOf(p.id) >=0
                p.checked=true
              else
                p.checked=false
          component.$update()
      )

    updateOrSaveUser:(user)->
      component = this

      if user.id
        if !user.password && user.re_password != user.password
          user.passerror=true
        else
          user.passerror=false
        permissions=[]
        for p in component.data.permissions
          if p.checked
            permissions.push(p)
        user.role.permissions=permissions
        $http.put('/api/v1.0/users',{user:user},(rep)->
          if rep
            component.user()
            component.$update()
            $('.modal.updateUser').modal('hide')
        )
      else
        if !user.username || !user.username.match(/^\w+$/)
          user.usernameerror=true
        else
          user.usernameerror=false

        if !user.first_name
          user.nameerror=true
        else
          user.nameerror=false

        if !user.password || user.re_password != user.password
          user.passerror=true
        else
          user.passerror=false

        for r in component.data.roles
          if r.checked
            role=r
        if !role
          user.roleerror=true
        else
          user.roleerror=false
          user.role=role
        if !user.usernameerror && !user.nameerror && !user.passerror && !user.roleerror
          $http.post('/api/v1.0/users',{user:user},(rep)->
            if rep
              component.user()
              component.$update()
              $('.modal.updateUser').modal('hide')
          )

        false

    new:->
      component = this
      s= false
      param={product:{}}
      newPName= component.data.newPName
      param.product.name=newPName
      if newPName && newPName!=""
        s= true
        component.data.newPNerror=false
      else
        s=false
        component.data.newPNerror=true
      newPBarCode= component.data.newPBarCode
      param.product.bar_code=newPBarCode
      if newPBarCode && newPBarCode!=""
        s= true
        component.data.newPBerror=false
      else
        s=false
        component.data.newPBerror=true

      newPCost= component.data.newPCost
      param.product.cost=newPCost
      if newPCost && !isNaN(newPCost) && newPCost!=""
        s= true
        component.data.newPCerror=false
      else
        s=false
        component.data.newPCerror=true

      newPDate=  component.data.newPDate
      param.product.date=newPDate
      if newPDate && newPDate.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}/)
        s= true
        component.data.newPDerror=false
      else
        s=false
        component.data.newPDerror=true

      if s
        $http.post('/api/v1.0/settings/products',param, (rep)->
          if rep
            component.data.products=rep
            component.data.newP=false
            component.$update()
        )


    update:(index)->
      component = this
      oldP=component.data.products[index]
      u=false
      param={product:{}}
      name= component.data.pName[index]
      param.product.name= name
      if name && oldP.name!= name && name!=""
        u=true

      barCode= component.data.pBarCode[index]
      param.product.bar_code= barCode
      if barCode && oldP.bar_code!= barCode && barCode!=""
        u=true

      cost=component.data.pCost[index]
      if cost && isNaN(cost)
        component.data.cerror[index]=true
        return
      else
        component.data.cerror[index]=false
        param.product.cost= cost
        if oldP.cost!= Number(cost)
          u=true

      date=component.data.pDate[index]
      if date && date.match(/\d{4}-\d{2}-\d{2} \d{2}:\d{2}/)
        component.data.derror[index]=false
        param.product.date= date
        if oldP.date!= date
          u=true
      else
        u=false
      if u
        $http.post('/api/v1.0/settings/products',param, (rep)->
            if rep
              component.data.products=rep
              component.data.updateP[index]=false
              component.$update()
          )


    job: (date)->
      component = this
      if date.start && date.end && date.start <= date.end
        component.data.sState.loading = true
        component.data.sState.error = false
        param =
          start: date.start, end: date.end, edb: component.data.edb, order: component.data.order, store: component.data.store,gift: component.data.gift
        if param.edb || param.order || param.store || param.gift
          component.data.cerror = false
          $http.put('/api/v1.0/settings/repick', param, (rep)->
            if rep
              component.data.rep =
                success: true, error: false
            else
              component.data.rep =
                success: false, error: true
            component.$update()
          )
        else
          component.data.cerror = true
      else
        component.data.sState.loading = false
        component.data.sState.error = true

    formatNum: (number, digit)->
      String(Number(number / 100).toFixed(digit))

    formatDate:(date)->
      if(!isNaN(date))
        new Date(date).format "yyyy-MM-dd HH:mm"
      else
        if date.length> 16
          date.substr(0,16)
        else
          date

    export: (sel, name, $event)->
      $($event.target).table2csv(sel, name)
  )
