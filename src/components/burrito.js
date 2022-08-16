import * as React from "react"
import { Link, withPrefix } from "gatsby"

const Burrito = ({ location, title, children }) => {
  const rootPath = `${__PATH_PREFIX__}/`
  const isRootPath = location.pathname === rootPath
  let header

  if (isRootPath) {
    header = (
      <h1 className="main-heading">
        <Link to={withPrefix("/")}>{title}</Link>
      </h1>
    )
  } else {
    header = (
      <Link className="header-link-home" to={withPrefix("/")}>
        {title}
      </Link>
    )
  }

  return (
    <div className="global-wrapper" data-is-root-path={isRootPath}>
      <header className="global-header">{header}</header>
      <main>{children}</main>
    </div>
  )
}

export default Burrito
